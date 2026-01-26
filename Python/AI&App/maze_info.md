

# 1. Algorithm class (one-line)

-   **Type:** cellular automaton / stochastic spatial growth (multi-source Eden model; also similar to competitive percolation / Richardson’s model / voter-like dynamics).
    
-   **Nature:** local, parallel, discrete-time, probabilistic, agent-based.
    

# 2. What the code does (mapping to your functions)

-   `init_grid(...)` → random **multi-source seeding** (places initial agent seeds).
    
-   Each time step:
    
    -   `step_grid(...)` iterates **every occupied cell** and (with probability `expansion_prob`) picks **one random empty 4-neighbor** to claim.
        
    -   Claims are collected in `claims` (a map from empty cell → list of claimant agent IDs).
        
    -   **Conflict resolution**: if >1 claimant, resolve by:
        
        -   `'random'` (uniform random pick), or
            
        -   `'strength'` (pick claimant with highest `strength`; tie broken randomly).
            
    -   The grid is updated in parallel (uses a copy `new_grid` to avoid sequential overwriting).
        
-   `run_domination(...)` repeats for `steps` or until full.
    

# 3. Theoretical connections / names you can use in slides

-   **Eden growth model** (stochastic surface growth where cells add neighbors).
    
-   **Competitive percolation / multi-source Richardson model** (multiple seeds spreading on lattice).
    
-   **Cellular automaton** (local update rules on a grid).
    
-   **Markov process** (state at t+1 depends only on state at t and random draws).
    
-   Conflict rules relate to **voter/majority dynamics** if you change them.
    

# 4. Complexity and performance

-   Naïve per-step cost: scanning all occupied cells → **O(h·w)** worst-case per step (grid size).
    
-   Total cost: **O(steps · h · w)**.
    
-   Memory: **O(h·w)** to store grid and history.
    
-   **Optimization:** maintain the _frontier_ (set of currently occupied cells with empty neighbors). If frontier size ≪ h·w, cost per step becomes **O(|frontier|)** — much faster for large sparse grids.
    

# 5. Limitations / modelling assumptions

-   Local and memoryless decisions (no long-range planning or pathfinding).
    
-   Expansion probability is uniform across all occupied cells — no fatigue or capacity limits.
    
-   Conflict modes are simple; they ignore e.g. multiple-step strategies or coalition effects.
    
-   No randomness coupling across cells — each claim independent aside from competition.