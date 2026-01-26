"""
competitive_cleaner_backend.py
Backend simulation for Competitive Cleaner.
Contains Grid, Agent classes and run_simulation() for headless runs.
"""
import random
from collections import deque, defaultdict
import heapq

# Grid cell states: 0 = clean, 1 = dirty, 2 = obstacle (optional)
class Grid:
    def __init__(self, rows=20, cols=30, dirt_prob=0.2, seed=None):
        self.rows = rows
        self.cols = cols
        self.rng = random.Random(seed)
        self.cells = [[1 if self.rng.random() < dirt_prob else 0 for _ in range(cols)] for _ in range(rows)]
        self.obstacles = set()

    def is_dirty(self, pos):
        r, c = pos
        return self.cells[r][c] == 1

    def clean(self, pos):
        r, c = pos
        if self.cells[r][c] == 1:
            self.cells[r][c] = 0
            return True
        return False

    def in_bounds(self, pos):
        r, c = pos
        return 0 <= r < self.rows and 0 <= c < self.cols

    def neighbors(self, pos):
        r, c = pos
        for dr, dc in [(1,0),(-1,0),(0,1),(0,-1)]:
            nr, nc = r+dr, c+dc
            if self.in_bounds((nr,nc)) and (nr,nc) not in self.obstacles:
                yield (nr, nc)

    def dirty_positions(self):
        for r in range(self.rows):
            for c in range(self.cols):
                if self.cells[r][c] == 1:
                    yield (r, c)

# Simple helpers for pathfinding
def manhattan(a, b):
    return abs(a[0]-b[0]) + abs(a[1]-b[1])

def bfs_path(grid, start, goal):
    start_t = tuple(start)
    goal_t = tuple(goal)
    if start_t == goal_t:
        return []
    q = deque([start_t])
    parent = {start_t: None}
    while q:
        cur = q.popleft()
        if cur == goal_t:
            # reconstruct
            path = []
            node = cur
            while parent[node] is not None:
                path.append(list(node))
                node = parent[node]
            path.reverse()
            return path
        for nb in grid.neighbors(cur):
            if nb not in parent:
                parent[nb] = cur
                q.append(nb)
    return []

def astar_path(grid, start, goal):
    start_t = tuple(start)
    goal_t = tuple(goal)
    if start_t == goal_t:
        return []
    open_heap = []
    heapq.heappush(open_heap, (manhattan(start_t, goal_t), 0, start_t))
    came_from = {}
    gscore = {start_t: 0}
    while open_heap:
        _, g, current = heapq.heappop(open_heap)
        if current == goal_t:
            path = []
            node = current
            while node != start_t:
                path.append(list(node))
                node = came_from[node]
            path.reverse()
            return path
        for nb in grid.neighbors(current):
            tentative = g + 1
            if nb not in gscore or tentative < gscore[nb]:
                gscore[nb] = tentative
                priority = tentative + manhattan(nb, goal_t)
                heapq.heappush(open_heap, (priority, tentative, nb))
                came_from[nb] = current
    return []

# Base Agent
class AgentBase:
    def __init__(self, name, grid, start_pos=None, seed=None):
        self.name = name
        self.grid = grid
        self.rng = random.Random(seed)
        if start_pos is None:
            self.pos = (self.rng.randrange(grid.rows), self.rng.randrange(grid.cols))
        else:
            self.pos = tuple(start_pos)
        self.cleaned = 0
        self.trace = [self.pos]

    def step(self):
        raise NotImplementedError

    def try_clean(self):
        if self.grid.clean(self.pos):
            self.cleaned += 1

# Random cleaner: moves randomly
class RandomCleaner(AgentBase):
    def step(self):
        neighbors = list(self.grid.neighbors(self.pos))
        if not neighbors:
            return
        self.pos = self.rng.choice(neighbors)
        self.try_clean()
        self.trace.append(self.pos)

# Greedy cleaner: move toward nearest dirty cell using BFS path
class GreedyCleaner(AgentBase):
    def __init__(self, name, grid, start_pos=None, seed=None):
        super().__init__(name, grid, start_pos, seed)
        self.path = []

    def find_nearest_dirty(self):
        best = None
        bestd = None
        for dpos in self.grid.dirty_positions():
            d = manhattan(self.pos, dpos)
            if best is None or d < bestd:
                best = dpos
                bestd = d
        return best

    def step(self):
        # if current cell is dirty, clean it
        if self.grid.is_dirty(self.pos):
            self.try_clean()
            return
        # if have path, follow it
        if self.path:
            self.pos = tuple(self.path.pop(0))
            self.try_clean()
            self.trace.append(self.pos)
            return
        target = self.find_nearest_dirty()
        if target is None:
            # wander if no dirt
            RandomCleaner.step(self)
            return
        self.path = bfs_path(self.grid, self.pos, target)
        if self.path:
            self.pos = tuple(self.path.pop(0))
            self.try_clean()
            self.trace.append(self.pos)

# A* cleaner: uses A* to plan to nearest dirty cell
class AStarCleaner(AgentBase):
    def __init__(self, name, grid, start_pos=None, seed=None):
        super().__init__(name, grid, start_pos, seed)
        self.path = []

    def find_nearest_dirty(self):
        best = None
        bestd = None
        for dpos in self.grid.dirty_positions():
            d = manhattan(self.pos, dpos)
            if best is None or d < bestd:
                best = dpos
                bestd = d
        return best

    def step(self):
        if self.grid.is_dirty(self.pos):
            self.try_clean()
            return
        if self.path:
            self.pos = tuple(self.path.pop(0))
            self.try_clean()
            self.trace.append(self.pos)
            return
        target = self.find_nearest_dirty()
        if target is None:
            RandomCleaner.step(self)
            return
        self.path = astar_path(self.grid, self.pos, target)
        if self.path:
            self.pos = tuple(self.path.pop(0))
            self.try_clean()
            self.trace.append(self.pos)

# Coverage cleaner: simple systematic sweeping (row-major)
class CoverageCleaner(AgentBase):
    def __init__(self, name, grid, start_pos=None, seed=None):
        super().__init__(name, grid, start_pos, seed)
        self.goal = (0,0)
        self.set_next_goal()

    def set_next_goal(self):
        # pick next cell in row-major order that is dirty (or just next cell)
        for r in range(self.grid.rows):
            for c in range(self.grid.cols):
                if (r,c) == self.pos:
                    continue
                # prefer dirty cells first
                if self.grid.is_dirty((r,c)):
                    self.goal = (r,c)
                    return
        # if no dirty cells, set to next cell lexicographically
        r, c = self.pos
        if c+1 < self.grid.cols:
            self.goal = (r, c+1)
        elif r+1 < self.grid.rows:
            self.goal = (r+1, 0)
        else:
            self.goal = (0,0)

    def step(self):
        if self.grid.is_dirty(self.pos):
            self.try_clean()
            return
        if self.pos == self.goal:
            self.set_next_goal()
        # move one step toward goal (simple greedy)
        r, c = self.pos
        gr, gc = self.goal
        dr = 0
        dc = 0
        if gr > r:
            dr = 1
        elif gr < r:
            dr = -1
        elif gc > c:
            dc = 1
        elif gc < c:
            dc = -1
        new = (r+dr, c+dc)
        if self.grid.in_bounds(new):
            self.pos = new
        self.try_clean()
        self.trace.append(self.pos)

def run_simulation(rows=20, cols=30, dirt_prob=0.25, agents_config=None, steps=1000, seed=None):
    """
    agents_config: list of tuples (agent_type:str, name:str, start_pos:tuple or None)
      agent_type in {'random','greedy','astar','coverage'}
    returns: grid, agents, history of cleaned counts per agent, final stats list
    """
    grid = Grid(rows=rows, cols=cols, dirt_prob=dirt_prob, seed=seed)
    agents = []
    rng = random.Random(seed)
    if agents_config is None:
        agents_config = [('greedy','Greedy', None), ('astar','AStar', None), ('random','Random', None)]
    for conf in agents_config:
        typ, name, start = conf
        if typ == 'random':
            agents.append(RandomCleaner(name, grid, start_pos=start, seed=rng.randint(0,10**9)))
        elif typ == 'greedy':
            agents.append(GreedyCleaner(name, grid, start_pos=start, seed=rng.randint(0,10**9)))
        elif typ == 'astar':
            agents.append(AStarCleaner(name, grid, start_pos=start, seed=rng.randint(0,10**9)))
        elif typ == 'coverage':
            agents.append(CoverageCleaner(name, grid, start_pos=start, seed=rng.randint(0,10**9)))
        else:
            raise ValueError("Unknown agent type: "+typ)
    cleaned_over_time = {a.name: [] for a in agents}
    for step in range(steps):
        for a in agents:
            a.step()
        for a in agents:
            cleaned_over_time[a.name].append(a.cleaned)
        # early stop if all clean
        any_dirty = False
        for _ in grid.dirty_positions():
            any_dirty = True
            break
        if not any_dirty:
            break
    stats = [(a.name, a.cleaned) for a in agents]
    stats.sort(key=lambda x: -x[1])
    return grid, agents, cleaned_over_time, stats