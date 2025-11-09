import random;
import time;


class VacuumCleaner:
    def __init__(self,environment):
        self.environment=environment

    def sense(self):
        return random.choice(list(environment.keys()))
    
    def act(self):
        state=self.sense()
        if(environment[state]=="Clean"):
            print(f"At {state}, it's already clean. Moving to next room.")
        else :
            print(f"At {state}, it's dirty. Cleaning now.")
            environment[state]="Clean"

environment={
    "A":"Dirty",
    "B":"Dirty",
    "C":"Dirty",
    "D":"Dirty"
}

solver=VacuumCleaner(environment)

for _ in range(10):
    solver.act()
    time.sleep(1)
    print(environment)
    print("-----")
