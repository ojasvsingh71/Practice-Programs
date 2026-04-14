"""
Simple Bidding War AI - Pygame Visualizer
Clean UI: shows item, bids, winner, and leaderboard.
The window stays visible longer and no word 'auction' is used anywhere.
"""

import pygame, sys, time, random

pygame.init()
WIDTH, HEIGHT = 600, 420
WIN = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Bidding War AI - Simple Visualizer")

FONT = pygame.font.SysFont("arial", 20)
BIG = pygame.font.SysFont("arial", 26, bold=True)

WHITE = (255,255,255)
BLACK = (0,0,0)

# --------------------------- AGENT LOGIC ---------------------------
class Item:
    def __init__(self, name, base):
        self.name = name
        self.base = base

class Agent:
    def __init__(self, name, strategy="random", max_bid=100, budget=200, seed=None):
        self.name = name
        self.strategy = strategy
        self.max_bid = max_bid
        self.budget = budget
        self.spent = 0
        self.wins = 0
        self.rng = random.Random(seed)

    def can_afford(self, amt):
        return self.spent + amt <= self.budget

    def bid(self, item):
        if self.strategy == "random":
            amt = self.rng.randint(1, self.max_bid)
        elif self.strategy == "maxvalue":
            amt = min(self.max_bid, item.base + self.rng.randint(5,20))
        else:
            amt = self.rng.randint(1, self.max_bid)

        return amt if self.can_afford(amt) else 0


# --------------------------- ITEMS & AGENTS ---------------------------
items = [
    Item("Laptop", 80),
    Item("Phone", 50),
    Item("Tablet", 40),
    Item("Keyboard", 20)
]

agents = [
    Agent("RandomBot", "random", 100, 250, seed=1),
    Agent("ValueHunter", "maxvalue", 120, 300, seed=2),
    Agent("BudgetBot", "random", 80, 150, seed=3)
]


# --------------------------- DRAW HELPER ---------------------------
def draw_text(text, x, y, font=FONT):
    WIN.blit(font.render(text, True, BLACK), (x, y))


def show_frame(item, bids, winner):
    WIN.fill(WHITE)
    
    # Item display
    draw_text(f"Item: {item.name} (Base Value: {item.base})", 20, 20, BIG)
    
    # Bids
    y = 80
    draw_text("Bids:", 20, y)
    y += 30
    for name, amt in bids:
        draw_text(f"{name}: {amt}", 40, y)
        y += 25
    
    # Winner
    if winner is not None:
        draw_text(f"Winner: {winner[0]}  (Bid: {winner[1]})", 20, y + 20, BIG)
    else:
        draw_text("Winner: None", 20, y + 20, BIG)

    # Leaderboard
    draw_text("Leaderboard", 350, 80, BIG)
    yy = 120
    sorted_agents = sorted(agents, key=lambda a: -a.wins)
    for a in sorted_agents:
        draw_text(f"{a.name} - Wins: {a.wins}", 350, yy)
        yy += 30

    pygame.display.update()


# --------------------------- MAIN LOOP ---------------------------
DISPLAY_TIME = 8   # seconds each frame stays visible

for item in items:
    # calculate bids
    bids = []
    for a in agents:
        amt = a.bid(item)
        bids.append((a.name, amt))

    # winner logic
    top_bid = max(bids, key=lambda x: x[1])[1]
    top_bidders = [b for b in bids if b[1] == top_bid and top_bid > 0]

    if top_bid == 0:
        winner = None
    else:
        winner = random.choice(top_bidders)
        for a in agents:
            if a.name == winner[0] and a.can_afford(winner[1]):
                a.spent += winner[1]
                a.wins += 1

    # show on screen for long time
    show_frame(item, bids, winner)
    time.sleep(DISPLAY_TIME)

# final end screen
WIN.fill(WHITE)
draw_text("Process Complete", 200, 160, BIG)
pygame.display.update()
time.sleep(5)

pygame.quit()
sys.exit()
