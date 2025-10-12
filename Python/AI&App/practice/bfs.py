from collections import deque

def bfs(graph,start,goal):
    visited=set()
    queue=deque([(start,[start])])  # (current_node, path_to_current_node)
    while queue:
        current,path=queue.popleft()
        if current==goal:
            return path
        visited.add(current)
        for neighbor in graph.get(current,[]):
            if neighbor not in visited and all(neighbor!=n[0] for n in queue):
                queue.append((neighbor,path+[neighbor]))
                
    return None

if __name__=="__main__":
    dict={}
    while(True):
        key=input("Enter the parent node : ").strip()
        if(key==""):
            break
        l=input(f"Enter the childhren of {key} seperated by spaces : ").strip()
        dict[key]=list(child.strip() for child in l.split(" ") if child.strip())

    start=input("Enter start node : ")
    goal=input("Enter goal node : ")

    solution=bfs(dict,start,goal)
    if(solution):
        print("Path from start to goal : ", " -> ".join(solution)) 
    else:
        print("No path found from start to goal")  
