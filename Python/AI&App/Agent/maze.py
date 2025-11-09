class MazeSolver():
    def __init__(self, start, goal):
        self.start=start
        self.goal=goal

    def goal_test(self, state):
        return state==self.goal
    
    def solve(self, state):
        if(state==self.goal):
            print("Goal reached!")
            return True
        
        x=state[0]
        y=state[1]

        if(x<self.goal[0]):
            x+=1
        elif(x>self.goal[0]):
            x-=1
        elif(y<self.goal[1]):
            y+=1
        elif(y>self.goal[1]):
            y-=1    
        
        print(f"Moving to {(x,y)}")
        new_state=(x,y)
        return self.solve(new_state)

solver=MazeSolver((0,0),(3,2))
solver.solve((0,0))