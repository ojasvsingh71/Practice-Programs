
# Overview (one-line)

`pray_cli.py` is an **agent-based, discrete-time simulation** of a pursuit–evasion scenario: multiple **predator** agents hunt multiple **prey** agents in a 2D continuous bounded world with static circular obstacles. The model is deterministic in rules but stochastic in initialization and some decisions (jitter, claim choices, seeds).

# High-level algorithm class

-   **Type:** Agent-based simulation (multi-agent, continuous-space).
    
-   **Related models:** pursuit–evasion, steering behaviors, predictive interception (simple linear lead), potential-field style obstacle avoidance.
    
-   **Not used:** no learning (no RL), no pathfinding graph — everything is local reactive control.
    

# Agents & their behaviours

### Prey (fleeing agent)

-   **Role:** escape / avoid predators.
    
-   **Inputs:** positions & velocities of predators, obstacle list.
    
-   **Decision rule:**
    
    1.  Find the **nearest predator** (Euclidean distance).
        
    2.  Compute an **away direction** = normalized vector from predator → prey.
        
    3.  Compute **obstacle avoidance** vector by summing repulsive contributions from nearby obstacles (if within influence range).
        
    4.  Add small random **jitter** to make motion natural and non-deterministic.
        
    5.  Combine away + avoid + jitter into a desired direction, then **steer** toward it with a limited maximum turn per step (`max_turn`).
        
    6.  Update velocity = normalized steering direction × speed, then integrate position `pos += velocity * dt`.
        
-   **Mechanics:** steering is implemented by computing the angular difference between current heading and desired heading, clamping the angular change, rotating the heading by that angle using a 2×2 rotation matrix, renormalizing.
    
-   **Keeps inside bounds** by clipping x/y to world limits.
    

### Predator (hunting agent)

-   **Role:** chase and capture prey.
    
-   **Inputs:** positions & velocities of prey, obstacles.
    
-   **Decision rule:**
    
    1.  Choose the **nearest prey** (simple greedy cooperation: each predator independently picks the closest prey).
        
    2.  Compute a **predictive interception target**: `target = prey_pos + prey_velocity * t_pred` where `t_pred ≈ dist / predator_speed`. (A simple linear lead; assumes prey continues at current velocity.)
        
    3.  Compute direction to `target` and add obstacle avoidance vector (similar repulsion).
        
    4.  Normalize to get heading, set velocity = heading × predator_speed, integrate position `pos += velocity * dt`.
        
-   **Capture test:** if `distance(predator, prey) <= capture_radius` then capture occurs and sim ends (or that prey removed in multi-prey variant).
    

# Core simulation loop

1.  Initialize random seed (optional) and spawn predators on left, prey on right with small randomness.
    
2.  For each discrete timestep up to `max_steps`:
    
    -   Update **all prey** (prey.step(...)).
        
    -   Update **all predators** (pred.step(...)).
        
    -   Save positions to trajectory lists.
        
    -   Check pairwise distances for capture (if predator within `capture_radius` of any prey).
        
3.  Stop on capture or when steps exhausted.
    

# Key mathematical pieces (brief)

-   **Normalization:** `dir /= np.linalg.norm(dir)` to get unit heading.
    
-   **Angle diff & rotation:**  
    `ang = atan2(des_y,des_x) - atan2(cur_y,cur_x)` → wrap to [-π,π] → `ang = clip(ang, -max, max)` → rotate `cur_dir` by `ang` using rotation matrix `[[cos,-sin],[sin,cos]]`.
    
-   **Interception estimate:** `t_pred = distance / predator_speed` then `pred_target = prey_pos + prey_vel * t_pred` (first-order linear prediction).
    
-   **Obstacle avoidance:** for each circle, add `(pos - center)/d * weight` when inside influence radius.
    

# Randomness & reproducibility

-   Random elements: initial headings, spawn positions, jitter, some claim choices (in earlier grid version), and seeds for experiments.
    
-   Use `np.random.seed(seed)` (and `random.seed(seed)` in improved script) for reproducible runs.
    

# Complexity & performance

-   Per step the simulation updates every agent → time per step = O(n_pred + n_prey). Trajectory memory is O(steps × (n_pred + n_prey)).
    
-   Obstacle checks are O(n_obstacles) per agent per step. For many obstacles, consider spatial hashing or KD-tree.
    

# Strengths and limitations (good for slides)

**Strengths**

-   Simple, robust reactive behaviors that are easy to explain and fast to run.
    
-   Predictive intercept gives realistic chasing (predator leads prey).
    
-   Obstacle avoidance creates interesting emergent trajectories.
    

**Limitations**

-   No planning or learning — predators greedily pick nearest prey and use a simple lead estimate (can fail vs sharp turns).
    
-   Interception uses approximate time estimate (no analytic quadratic solve for exact intercept).
    
-   Obstacles are avoided locally (not guaranteed globally optimal path; predators/prey can get stuck near obstacles).
    

# What to say in a 1–2 minute demo script

-   “Each prey tries to flee the nearest predator while avoiding obstacles and turning with limited agility. Predators pick the nearest prey and attempt to intercept by predicting where the prey will be, then move toward that predicted point. Capture happens when a predator gets within a small radius of a prey. The result shows how speed, turning limits, and obstacles change the chase outcome.”
    
-   Point out one demo change: “Increase prey speed to X → prey escapes; increase predator speed to Y → predator catches.”
    

# Quick ideas if you want to upgrade (pick one)

-   Replace the linear `t_pred = dist / predator_speed` with an **analytic intercept** solving relative motion quadratic (gives true lead time when feasible).
    
-   Add **cooperative strategy**: predators assign themselves to different prey using Hungarian algorithm to minimize time-to-capture.
    
-   Use **A*** path planning around obstacles (discretize world) for long-range navigation rather than local potential-field avoidance.
    
-   Train a small RL policy for predators (heavier work) — show learned vs heuristic.