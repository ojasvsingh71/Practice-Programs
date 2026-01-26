# pray_cli.py
# Usage examples:
# python pray_cli.py --preset capture
# python pray_cli.py --pred 2 --prey 3 --pred-speed 1.8 --prey-speed 1.2
# python pray_cli.py --heatmap --grid 7 --trials 6

import argparse
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation

# --- simulation core (same logic as before) ---
xlim, ylim = (0, 20), (-10, 10)

def clamp(v, a, b):
    return max(a, min(b, v))

class Agent:
    def __init__(self, pos, speed=1.0):
        self.pos = np.array(pos, dtype=float)
        self.speed = float(speed)
        self.velocity = np.zeros(2)
    def distance_to(self, other):
        return np.linalg.norm(self.pos - other.pos)

class Prey(Agent):
    def __init__(self, pos, speed=1.2, max_turn=np.pi/3):
        super().__init__(pos, speed)
        v = np.random.randn(2)
        self.velocity = v / np.linalg.norm(v) * self.speed
        self.max_turn = max_turn
    def step(self, predators, obstacles, dt=0.1):
        if len(predators) > 0:
            dists = [np.linalg.norm(self.pos - p.pos) for p in predators]
            nearest = predators[int(np.argmin(dists))]
            away = self.pos - nearest.pos
            if np.linalg.norm(away) < 1e-6:
                away = np.random.randn(2)
            away_dir = away / np.linalg.norm(away)
        else:
            away_dir = np.random.randn(2)
            away_dir /= np.linalg.norm(away_dir)
        avoid = np.zeros(2)
        for (ox, oy, r) in obstacles:
            vec = self.pos - np.array([ox, oy]); d = np.linalg.norm(vec)
            if d < (r + 1.0):
                avoid += (vec / max(1e-3, d)) * (1.0 + (r + 1.0 - d))
        jitter = np.random.randn(2) * 0.2
        desired = away_dir + 0.7 * avoid + 0.3 * jitter
        if np.linalg.norm(desired) < 1e-6:
            desired = np.random.randn(2)
        desired /= np.linalg.norm(desired)
        cur_dir = self.velocity / np.linalg.norm(self.velocity)
        ang = np.arctan2(desired[1], desired[0]) - np.arctan2(cur_dir[1], cur_dir[0])
        ang = (ang + np.pi) % (2*np.pi) - np.pi
        ang = np.clip(ang, -self.max_turn*dt*6, self.max_turn*dt*6)
        c, s = np.cos(ang), np.sin(ang); R = np.array([[c, -s],[s, c]])
        new_dir = R.dot(cur_dir)
        self.velocity = new_dir / np.linalg.norm(new_dir) * self.speed
        self.pos += self.velocity * dt
        self.pos[0] = clamp(self.pos[0], xlim[0], xlim[1])
        self.pos[1] = clamp(self.pos[1], ylim[0], ylim[1])

class Predator(Agent):
    def __init__(self, pos, speed=1.6):
        super().__init__(pos, speed); self.velocity = np.zeros(2)
    def interception_target(self, prey):
        q = prey.pos; vq = prey.velocity; rel = q - self.pos
        if np.dot(vq, vq) < 1e-6:
            return q
        dist = np.linalg.norm(rel); t_pred = dist / (self.speed + 1e-6)
        return q + vq * t_pred
    def step(self, preys, obstacles, dt=0.1):
        if len(preys) == 0:
            if np.linalg.norm(self.velocity) < 1e-6:
                self.velocity = np.array([1.0, 0.0]) * self.speed
            self.pos += self.velocity * dt; return
        dists = [np.linalg.norm(self.pos - q.pos) for q in preys]
        target_prey = preys[int(np.argmin(dists))]
        target_point = self.interception_target(target_prey)
        dir_to = target_point - self.pos
        dir_unit = np.zeros(2) if np.linalg.norm(dir_to) < 1e-8 else dir_to / np.linalg.norm(dir_to)
        avoid = np.zeros(2)
        for (ox, oy, r) in obstacles:
            vec = self.pos - np.array([ox, oy]); d = np.linalg.norm(vec)
            if d < (r + 1.0):
                avoid += (vec / max(1e-3, d)) * (1.0 + (r + 1.0 - d))
        desired = dir_unit + 0.5 * avoid
        if np.linalg.norm(desired) < 1e-6: desired = dir_unit
        desired /= np.linalg.norm(desired)
        self.velocity = desired * self.speed
        self.pos += self.velocity * dt
        self.pos[0] = clamp(self.pos[0], xlim[0], xlim[1]); self.pos[1] = clamp(self.pos[1], ylim[0], ylim[1])

def run_multi_sim(n_pred=1, n_prey=1, predator_speed=1.6, prey_speed=1.2, obstacles=None, seed=None, dt=0.1, max_steps=600, capture_radius=0.3):
    if seed is not None: np.random.seed(int(seed))
    if obstacles is None: obstacles=[]
    preds=[]; preys=[]
    for i in range(n_pred): preds.append(Predator((1.0+np.random.rand()*2.0, 1.0+np.random.rand()*8.0), predator_speed))
    for i in range(n_prey): preys.append(Prey((8.0+np.random.rand()*1.5, 1.0+np.random.rand()*8.0), prey_speed))
    prey_trajs=[[] for _ in range(n_prey)]; pred_trajs=[[] for _ in range(n_pred)]
    for step in range(max_steps):
        for i, prey in enumerate(preys): prey.step(preds, obstacles, dt=dt)
        for j, pred in enumerate(preds): pred.step(preys, obstacles, dt=dt)
        for i, prey in enumerate(preys): prey_trajs[i].append(prey.pos.copy())
        for j, pred in enumerate(preds): pred_trajs[j].append(pred.pos.copy())
        for i, prey in enumerate(preys):
            for j, pred in enumerate(preds):
                if np.linalg.norm(pred.pos - prey.pos) <= capture_radius:
                    return prey_trajs, pred_trajs, True, {'step': step, 'predator': j, 'prey': i}
    return prey_trajs, pred_trajs, False, None

# --- visualization helpers ---
def show_sim(prey_trajs, pred_trajs, obstacles):
    fig, ax = plt.subplots(figsize=(6,6)); ax.set_xlim(xlim); ax.set_ylim(ylim)
    for (ox, oy, r) in obstacles: ax.add_patch(plt.Circle((ox,oy), r, color='gray', alpha=0.4))
    for traj in prey_trajs:
        traj=np.array(traj); 
        if traj.size==0: continue
        ax.plot(traj[:,0], traj[:,1], '-', linewidth=1.5)
        ax.scatter(traj[0,0], traj[0,1], marker='o')
    for traj in pred_trajs:
        traj=np.array(traj)
        if traj.size==0: continue
        ax.plot(traj[:,0], traj[:,1], '--', linewidth=1.5)
        ax.scatter(traj[0,0], traj[0,1], marker='s')
    plt.show()

def animate_sim(prey_trajs, pred_trajs, obstacles, interval=50):
    fig2, ax2 = plt.subplots(figsize=(6,6)); ax2.set_xlim(xlim); ax2.set_ylim(ylim)
    for (ox, oy, r) in obstacles: ax2.add_patch(plt.Circle((ox,oy), r, color='gray', alpha=0.4))
    prey_artists=[ax2.plot([], [], 'o', markersize=8)[0] for _ in prey_trajs]
    pred_artists=[ax2.plot([], [], 's', markersize=8)[0] for _ in pred_trajs]
    prey_trails=[ax2.plot([], [], '-', linewidth=1)[0] for _ in prey_trajs]
    pred_trails=[ax2.plot([], [], '--', linewidth=1)[0] for _ in pred_trajs]
    max_len = max([len(t) for t in prey_trajs + pred_trajs] or [1])
    def update(i):
        for idx, traj in enumerate(prey_trajs):
            if len(traj)==0:
                prey_artists[idx].set_data([], []); prey_trails[idx].set_data([], [])
                continue
            j = min(i, len(traj)-1)
            prey_artists[idx].set_data([traj[j][0]], [traj[j][1]])
            tarr = np.array(traj[:j+1]); prey_trails[idx].set_data(tarr[:,0], tarr[:,1])
        for idx, traj in enumerate(pred_trajs):
            if len(traj)==0:
                pred_artists[idx].set_data([], []); pred_trails[idx].set_data([], [])
                continue
            j = min(i, len(traj)-1)
            pred_artists[idx].set_data([traj[j][0]], [traj[j][1]])
            tarr = np.array(traj[:j+1]); pred_trails[idx].set_data(tarr[:,0], tarr[:,1])
        return prey_artists + pred_artists + prey_trails + pred_trails
    ani = animation.FuncAnimation(fig2, update, frames=max_len, interval=interval, blit=False)
    plt.show()

# --- heatmap helper (runs many sims) ---
def capture_prob_grid(pred_speeds, prey_speeds, trials_per_cell=6, seed_base=0):
    grid = np.zeros((len(prey_speeds), len(pred_speeds)))
    for i, ps in enumerate(prey_speeds):
        for j, pd in enumerate(pred_speeds):
            succ = 0
            for t in range(trials_per_cell):
                seed = seed_base + i*1000 + j*100 + t
                _, _, captured, _ = run_multi_sim(n_pred=1, n_prey=1, predator_speed=pd, prey_speed=ps, obstacles=[(5,5,1.2)], seed=seed, max_steps=400)
                succ += 1 if captured else 0
            grid[i, j] = succ / trials_per_cell
    return grid

# --- CLI entrypoint ---
def main():
    p = argparse.ArgumentParser()
    p.add_argument('--pred', type=int, default=1)
    p.add_argument('--prey', type=int, default=1)
    p.add_argument('--pred-speed', type=float, default=1.6)
    p.add_argument('--prey-speed', type=float, default=1.2)
    p.add_argument('--seed', type=int, default=1)
    p.add_argument('--preset', choices=['default','capture','escape','multipred'], default='default')
    p.add_argument('--heatmap', action='store_true')
    p.add_argument('--grid', type=int, default=9)
    p.add_argument('--trials', type=int, default=6)
    args = p.parse_args()

    if args.preset == 'capture':
        args.pred = 1; args.prey = 1; args.pred_speed = 2.0; args.prey_speed = 1.2
    elif args.preset == 'escape':
        args.pred = 1; args.prey = 1; args.pred_speed = 1.6; args.prey_speed = 1.9
    elif args.preset == 'multipred':
        args.pred = 3; args.prey = 4; args.pred_speed = 1.8; args.prey_speed = 1.2

    if args.heatmap:
        pred_speeds = np.linspace(0.8, 2.4, args.grid)
        prey_speeds = np.linspace(0.8, 2.4, args.grid)
        print(f'Running heatmap ({args.grid}x{args.grid} x {args.trials} trials) — may take time...')
        grid = capture_prob_grid(pred_speeds, prey_speeds, trials_per_cell=args.trials)
        plt.figure(figsize=(6,5))
        plt.imshow(grid, origin='lower', extent=[pred_speeds[0], pred_speeds[-1], prey_speeds[0], prey_speeds[-1]], aspect='auto', vmin=0, vmax=1)
        plt.xlabel('Predator speed'); plt.ylabel('Prey speed'); plt.title('Capture Probability')
        plt.colorbar(label='capture probability'); plt.show()
        return

    obstacles = [
        (6.0, 0.0, 1.8),
        (10.0,2.5,1.5),
        (12.5,-0.5,1.5),
        (10.0, -4.0, 3.2),
        (12.5, 3.0, 1.6),
        (16.0, -2.5, 1.4),
        (8.5, 5.0, 1.0),
        (12.0, -7.0, 1.2)
    ]
    prey_trajs, pred_trajs, captured, info = run_multi_sim(n_pred=args.pred, n_prey=args.prey,
                                                          predator_speed=args.pred_speed, prey_speed=args.prey_speed,
                                                          obstacles=obstacles, seed=args.seed, max_steps=800, capture_radius=0.3)
    print("Captured:", captured, "Info:", info)
    show_sim(prey_trajs, pred_trajs, obstacles)
    animate_sim(prey_trajs, pred_trajs, obstacles)

if __name__ == '__main__':
    main()
