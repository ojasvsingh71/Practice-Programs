"""
bidding_war.py
Backend CLI version of Bidding War AI Simulation.
Run: python bidding_war.py
"""
import random

class Item:
    def __init__(self, name, base_price):
        self.name = name
        self.base_price = base_price

class Agent:
    def __init__(self, name, strategy="random", max_bid=100, budget=300, seed=None):
        self.name = name
        self.strategy = strategy
        self.max_bid = max_bid
        self.budget = budget
        self.spent = 0
        self.wins = []
        self._rng = random.Random(seed)

    def can_afford(self, amount):
        return (self.spent + amount) <= self.budget

    def bid(self, item):
        if self.strategy == "random":
            amount = self._rng.randint(1, self.max_bid)
            return amount if self.can_afford(amount) else 0
        if self.strategy == "maxvalue":
            amount = min(self.max_bid, item.base_price + self._rng.randint(5, 20))
            return amount if self.can_afford(amount) else 0
        if self.strategy == "budget":
            remaining = self.budget - self.spent
            if remaining < self.budget * 0.3:
                amount = self._rng.randint(1, 20)
            else:
                amount = self._rng.randint(20, self.max_bid)
            return amount if self.can_afford(amount) else 0
        return 0

def run_auction(items, agents, verbose=True):
    bidding_history = []
    for item in items:
        round_bids = []
        for agent in agents:
            amt = agent.bid(item)
            round_bids.append((agent.name, amt))
        # winner is highest bid (ties broken randomly among top bidders)
        top = max(round_bids, key=lambda x: x[1])[1]
        top_bidders = [n for n,a in round_bids if a == top]
        winner_name = None
        winning_amount = top
        if top == 0:
            winner_name = None
        elif len(top_bidders) == 1:
            winner_name = top_bidders[0]
        else:
            winner_name = random.choice(top_bidders)
        # apply spending
        if winner_name is not None:
            for agent in agents:
                if agent.name == winner_name and agent.can_afford(winning_amount):
                    agent.spent += winning_amount
                    agent.wins.append(item.name)
        bidding_history.append({
            "item": item.name,
            "base": item.base_price,
            "bids": round_bids,
            "winner": winner_name,
            "winning_bid": winning_amount
        })
        if verbose:
            print(f"Item: {item.name} (base {item.base_price})")
            for n, a in round_bids:
                print(f"  {n}: {a}")
            print(f"  Winner: {winner_name} (bid {winning_amount})\\n")
    return bidding_history, agents

def print_summary(bidding_history, agents):
    print("\\n===== AUCTION SUMMARY =====")
    for r in bidding_history:
        print(f"Item: {r['item']} | Winner: {r['winner']} | Bid: {r['winning_bid']}")
    print("\\n===== AGENT SUMMARY =====")
    for ag in agents:
        print(f"{ag.name}: Wins={len(ag.wins)}, Spent={ag.spent}, Items={ag.wins}")

if __name__ == '__main__':
    items = [Item('Laptop', 80), Item('Phone', 50), Item('Tablet',40), Item('Headphones',20), Item('Keyboard',15)]
    agents = [
        Agent('RandomBot', strategy='random', max_bid=100, budget=250, seed=1),
        Agent('ValueHunter', strategy='maxvalue', max_bid=120, budget=300, seed=2),
        Agent('BudgetMaster', strategy='budget', max_bid=80, budget=150, seed=3)
    ]
    history, agents = run_auction(items, agents)
    print_summary(history, agents)
