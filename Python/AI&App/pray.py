# pray_standalone_fixed.py
# Standalone predator-prey animation (no widgets). Save and run with: python pray_standalone_fixed.py

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation

# bounds
xlim, ylim = (0, 30), (0, 30)

class Agent:
    def __init__(self, pos, speed=1.0):
        self.pos = np.array(pos, dtype=float)
        self.speed = float(speed)
    def distance_to(self, other):
        return np.linalg.norm(self.pos - other.pos)

class Prey(Agent):
    def __init__(self, pos, speed=1.2):
        super().__init__(pos, speed)
        self.velocity = np.random.randn(2)
        self.velocity = self.velocity / np.linalg.norm(self.velocity) * self.speed
        self.max_turn = np.pi/4

    def step(self, predator, dt=0.1):
        away = self.pos - predator.pos
        if np.linalg.norm(away) < 1e-6:
            away = np.random.randn(2)
        away_dir = away / np.linalg.norm(away)
        jitter = np.random.randn(2) * 0.3
        desired = away_dir + 0.5 * jitter

        if np.linalg.norm(self.velocity) < 1e-8:
            self.velocity = np.array([1.0, 0.0])
        cur_dir = self.velocity / np.linalg.norm(self.velocity)
        des_dir = desired / np.linalg.norm(desired)
        ang = np.arctan2(des_dir[1], des_dir[0]) - np.arctan2(cur_dir[1], cur_dir[0])
        ang = (ang + np.pi) % (2*np.pi) - np.pi
        ang = np.clip(ang, -self.max_turn*0.1*10, self.max_turn*0.1*10)
        c, s = np.cos(ang), np.sin(ang)
        R = np.array([[c, -s], [s, c]])
        new_dir = R.dot(cur_dir)
        self.velocity = new_dir / np.linalg.norm(new_dir) * self.speed
        self.pos += self.velocity * dt
        self.pos[0] = np.clip(self.pos[0], xlim[0], xlim[1])
        self.pos[1] = np.clip(self.pos[1], ylim[0], ylim[1])

class Predator(Agent):
    def __init__(self, pos, speed=1.6):
        super().__init__(pos, speed)
        self.velocity = np.zeros(2)

    def interception_target(self, prey):
        q = prey.pos
        vq = getattr(prey, "velocity", np.zeros(2))
        rel = q - self.pos
        if np.dot(vq, vq) < 1e-6:
            return q
        dist = np.linalg.norm(rel)
        t_pred = dist / (self.speed + 1e-6)
        return q + vq * t_pred

    def step(self, prey, dt=0.1):
        target = self.interception_target(prey)
        dir_to = target - self.pos
        if np.linalg.norm(dir_to) < 1e-8:
            dir_unit = np.zeros(2)
        else:
            dir_unit = dir_to / np.linalg.norm(dir_to)
        self.velocity = dir_unit * self.speed
        self.pos += self.velocity * dt
        self.pos[0] = np.clip(self.pos[0], xlim[0], xlim[1])
        self.pos[1] = np.clip(self.pos[1], ylim[0], ylim[1])

def run_simulation(prey_start=(8,5), pred_start=(2,2), prey_speed=1.2, pred_speed=1.6, max_steps=800, capture_radius=0.3, seed=1):
    np.random.seed(seed)
    prey = Prey(prey_start, prey_speed)
    pred = Predator(pred_start, pred_speed)
    prey_traj, pred_traj = [], []
    captured = False
    capture_step = None
    for step in range(max_steps):
        prey.step(pred, dt=0.1)
        pred.step(prey, dt=0.1)
        prey_traj.append(prey.pos.copy())
        pred_traj.append(pred.pos.copy())
        if pred.distance_to(prey) <= capture_radius:
            captured = True
            capture_step = step
            break
    return np.array(prey_traj), np.array(pred_traj), captured, capture_step

if __name__ == "__main__":
    prey_traj, pred_traj, captured, capture_step = run_simulation()
    print("Captured:", captured, "Capture step:", capture_step)

    # animate using matplotlib interactive window
    fig, ax = plt.subplots()
    ax.set_xlim(xlim); ax.set_ylim(ylim)
    prey_dot, = ax.plot([], [], 'o', markersize=8)
    pred_dot, = ax.plot([], [], 's', markersize=8)
    trail_prey, = ax.plot([], [], '-', linewidth=1)
    trail_pred, = ax.plot([], [], '-', linewidth=1)

    def init():
        prey_dot.set_data([], []); pred_dot.set_data([], [])
        trail_prey.set_data([], []); trail_pred.set_data([], [])
        return prey_dot, pred_dot, trail_prey, trail_pred

    def update(i):
        # ensure safe indexing
        i = min(i, len(prey_traj)-1)
        # IMPORTANT: set_data for single markers must receive sequences (even for one point)
        prey_dot.set_data([prey_traj[i,0]], [prey_traj[i,1]])
        pred_dot.set_data([pred_traj[i,0]], [pred_traj[i,1]])
        trail_prey.set_data(prey_traj[:i+1,0], prey_traj[:i+1,1])
        trail_pred.set_data(pred_traj[:i+1,0], pred_traj[:i+1,1])
        return prey_dot, pred_dot, trail_prey, trail_pred

    ani = animation.FuncAnimation(fig, update, init_func=init, frames=max(1, len(prey_traj)), interval=40, blit=False)
    plt.show()
