"""
competitive_cleaner_gui.py
Pygame visualizer for the Competitive Cleaner simulation.
FEATURES:
✔ LIVE leaderboard
✔ Freeze when all dirt cleaned
✔ Wait 5 seconds AFTER cleaning, then quit
"""

import pygame
import sys
import time
from competitive_cleaner_backend import Grid, RandomCleaner, GreedyCleaner, AStarCleaner, CoverageCleaner

pygame.init()
CELL = 25

# parameters
ROWS = 20
COLS = 30
WIDTH = COLS * CELL
HEIGHT = ROWS * CELL + 60
WIN = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Competitive Cleaner - Freeze After Clean + Auto Quit")

# colors
WHITE = (255,255,255)
BLACK = (0,0,0)
DIRT_COLOR = (160, 110, 50)

AGENT_COLORS = {
    "Greedy": (0, 100, 200),
    "AStar": (200, 30, 30),
    "Random": (30, 180, 30),
    "Coverage": (200, 180, 30)
}

FONT = pygame.font.SysFont("arial", 22, bold=True)


def draw_grid(grid, agents):
    """Draws grid + agents + LIVE leaderboard."""
    WIN.fill(WHITE)

    # --- GRID ---
    for r in range(grid.rows):
        for c in range(grid.cols):
            rect = pygame.Rect(c*CELL, r*CELL, CELL, CELL)

            if grid.cells[r][c] == 1:
                pygame.draw.rect(WIN, DIRT_COLOR, rect)
            else:
                pygame.draw.rect(WIN, WHITE, rect)

            pygame.draw.rect(WIN, BLACK, rect, 1)

    # --- AGENTS ---
    for a in agents:
        r, c = a.pos
        rect = pygame.Rect(c*CELL, r*CELL, CELL, CELL)
        pygame.draw.rect(WIN, AGENT_COLORS[a.name], rect)

    # --- LEADERBOARD BAR ---
    pygame.draw.rect(WIN, BLACK, (0, ROWS*CELL, WIDTH, 60))

    # --- Text scores ---
    x_offset = 10
    for a in agents:
        text = f"{a.name}: {a.cleaned}"
        label = FONT.render(text, True, WHITE)
        WIN.blit(label, (x_offset, ROWS*CELL + 15))
        x_offset += 150

    pygame.display.update()


def all_dirt_cleaned(grid):
    """Returns True if every cell is clean."""
    for r in range(grid.rows):
        for c in range(grid.cols):
            if grid.cells[r][c] == 1:
                return False
    return True


def run_gui():
    grid = Grid(rows=ROWS, cols=COLS, dirt_prob=0.25, seed=42)

    agents = [
        GreedyCleaner("Greedy", grid, start_pos=(0,0), seed=1),
        AStarCleaner("AStar", grid, start_pos=(ROWS-1, COLS-1), seed=2),
        RandomCleaner("Random", grid, start_pos=(0, COLS-1), seed=3),
    ]

    clock = pygame.time.Clock()
    running = True

    dirt_cleared_time = None   # to start 5 sec countdown

    while running:
        clock.tick(10)

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

        # --- Check dirt cleaned ---
        if all_dirt_cleaned(grid):
            if dirt_cleared_time is None:
                dirt_cleared_time = time.time()  # mark time cleaning finished
            else:
                # Wait 5 seconds AFTER cleaning
                if time.time() - dirt_cleared_time >= 5:
                    print("\n------ FINAL SCORES ------")
                    for a in agents:
                        print(f"{a.name}: {a.cleaned}")
                    print("---------------------------\n")
                    running = False

            # Freeze movement (do NOT update agents)
            draw_grid(grid, agents)
            continue

        # If dirt still exists → move agents normally
        for a in agents:
            a.step()

        draw_grid(grid, agents)

    pygame.quit()


if __name__ == "__main__":
    run_gui()
