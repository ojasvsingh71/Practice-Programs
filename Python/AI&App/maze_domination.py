# maze_domination.py

# python maze_domination.py --preset default
# python maze_domination.py --preset fast
# python maze_domination.py --preset even
# python maze_domination.py --preset chaos


import argparse
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation
import random

# --- core (same as interactive functions) ---
def clamp(v, a, b): return max(a, min(b, v))

def init_grid(h, w, n_agents, seed=None):
    if seed is not None:
        random.seed(int(seed)); np.random.seed(int(seed))
    grid = np.zeros((h, w), dtype=int)
    positions = []
    for i in range(n_agents):
        for _ in range(200):
            if i == 0:
                pos = (np.random.randint(0, 2), np.random.randint(0, 2))
            elif i == 1:
                pos = (np.random.randint(0, 2), np.random.randint(w-2, w))
            elif i == 2:
                pos = (np.random.randint(h-2, h), np.random.randint(0, 2))
            elif i == 3:
                pos = (np.random.randint(h-2, h), np.random.randint(w-2, w))
            else:
                pos = (np.random.randint(0, h), np.random.randint(0, w))
            if grid[pos] == 0:
                too_close = False
                for p in positions:
                    if abs(p[0]-pos[0]) + abs(p[1]-pos[1]) < max(h,w)//8:
                        too_close = True; break
                if not too_close:
                    positions.append(pos)
                    grid[pos] = i+1
                    break
    for i in range(n_agents):
        if not np.any(grid == (i+1)):
            empty = np.argwhere(grid==0)
            if empty.size==0: break
            r = empty[np.random.choice(len(empty))]
            grid[r[0], r[1]] = i+1
    return grid

def neighbors4(y, x, h, w):
    for dy, dx in ((-1,0),(1,0),(0,-1),(0,1)):
        ny, nx = y+dy, x+dx
        if 0 <= ny < h and 0 <= nx < w:
            yield ny, nx

def step_grid(grid, n_agents, expansion_prob, strengths, conflict_mode='random'):
    h, w = grid.shape
    claims = {}
    occupied_positions = np.argwhere(grid > 0)
    for (y,x) in occupied_positions:
        agent = int(grid[y,x])
        if np.random.rand() > expansion_prob:
            continue
        empty_neigh = [(ny,nx) for (ny,nx) in neighbors4(y,x,h,w) if grid[ny,nx]==0]
        if not empty_neigh:
            continue
        ny, nx = empty_neigh[np.random.randint(len(empty_neigh))]
        claims.setdefault((ny,nx), []).append(agent)
    new_grid = grid.copy()
    for cell, claimers in claims.items():
        if len(claimers) == 1:
            winner = claimers[0]
        else:
            if conflict_mode == 'random':
                winner = random.choice(claimers)
            elif conflict_mode == 'strength':
                max_s = max(strengths[a-1] for a in claimers)
                top = [a for a in claimers if strengths[a-1] == max_s]
                winner = random.choice(top)
            else:
                winner = random.choice(claimers)
        new_grid[cell] = winner
    return new_grid

def run_domination(h, w, n_agents, expansion_prob, strengths, steps, conflict_mode='random', seed=None):
    grid = init_grid(h, w, n_agents, seed=seed)
    history = [grid.copy()]
    for t in range(steps):
        grid = step_grid(grid, n_agents, expansion_prob, strengths, conflict_mode=conflict_mode)
        history.append(grid.copy())
        if np.all(grid != 0):
            break
    return history

def compute_percentages(grid, n_agents):
    h, w = grid.shape
    total = h*w
    pct = {}
    for a in range(1, n_agents+1):
        pct[a] = np.sum(grid==a) / total * 100.0
    empty_pct = np.sum(grid==0) / total * 100.0
    return pct, empty_pct

# --- visualization ---
def show_final(grid):
    n_agents = int(np.max(grid))
    cmap = plt.cm.get_cmap('tab20', max(2, n_agents+1))
    fig, ax = plt.subplots(figsize=(6,6))
    ax.imshow(grid, cmap=cmap, vmin=0, vmax=max(1,n_agents))
    ax.set_title('Final territory (0 = empty)')
    ax.axis('off')
    plt.show()

def animate_history(history, interval=100):
    n_agents = int(np.max(history[-1]))
    cmap = plt.cm.get_cmap('tab20', max(2, n_agents+1))
    fig, ax = plt.subplots(figsize=(6,6))
    im = ax.imshow(history[0], cmap=cmap, vmin=0, vmax=max(1,n_agents), interpolation='nearest')
    ax.axis('off')
    def update(i):
        im.set_data(history[i])
        ax.set_title(f"Step {i}")
        return (im,)
    anim = animation.FuncAnimation(fig, update, frames=len(history), interval=interval, blit=False)
    plt.show()

# --- CLI ---
def main():
    p = argparse.ArgumentParser()
    p.add_argument('--grid', type=int, default=30)
    p.add_argument('--agents', type=int, default=4)
    p.add_argument('--exp', type=float, default=0.6)
    p.add_argument('--steps', type=int, default=120)
    p.add_argument('--conflict', choices=['random','strength'], default='random')
    p.add_argument('--seed', type=int, default=1)
    p.add_argument('--preset', choices=['default','fast','even','chaos'], default='default')
    args = p.parse_args()
    if args.preset == 'fast':
        args.exp = 0.95; args.steps = 80; args.agents = 3; args.grid = 40
    elif args.preset == 'even':
        args.exp = 0.5; args.steps = 200; args.agents = 6; args.grid = 40
    elif args.preset == 'chaos':
        args.exp = 0.8; args.steps = 120; args.agents = 10; args.grid = 50

    h = args.grid; w = args.grid; n_agents = args.agents
    if args.conflict == 'strength':
        strengths = [1.0 + 0.2*np.random.rand() for _ in range(n_agents)]
    else:
        strengths = [1.0]*n_agents
    history = run_domination(h, w, n_agents, args.exp, strengths, args.steps, conflict_mode=args.conflict, seed=args.seed)
    final = history[-1]
    pct, empty_pct = compute_percentages(final, n_agents)
    print(f"Final occupancy after {len(history)-1} steps (empty {empty_pct:.2f}%):")
    for a in range(1, n_agents+1):
        print(f"  Agent {a}: {pct[a]:.2f}%")
    show_final(final)
    animate_history(history, interval=80)

if __name__ == '__main__':
    main()
