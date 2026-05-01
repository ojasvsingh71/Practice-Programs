#include <stdio.h>
#include <limits.h>
#include <stdbool.h>

// Number of vertices in the graph
#define V 9 

// Utility function to find the vertex with the minimum distance value, 
// from the set of vertices not yet included in the shortest path tree
int minDistance(int dist[], bool visited[]) {
    int min = INT_MAX, min_index;

    for (int v = 0; v < V; v++) {
        if (visited[v] == false && dist[v] <= min) {
            min = dist[v];
            min_index = v;
        }
    }
    return min_index;
}

// Recursive function to print the shortest path from source to current vertex
void printPath(int parent[], int j) {
    // Base Case: If j is source
    if (parent[j] == -1) {
        printf("%d", j);
        return;
    }
    printPath(parent, parent[j]);
    printf(" -> %d", j);
}

// Main function that implements Dijkstra's single source shortest path algorithm
void dijkstra(int graph[V][V], int src, int dest) {
    int dist[V];      // dist[i] holds the shortest distance from src to i
    bool visited[V];  // visited[i] is true if vertex i is included in shortest path tree
    int parent[V];    // parent[i] stores the shortest path structure

    // Initialize all distances as INFINITE and visited[] as false
    for (int i = 0; i < V; i++) {
        parent[i] = -1;
        dist[i] = INT_MAX;
        visited[i] = false;
    }

    // Distance of source vertex from itself is always 0
    dist[src] = 0;

    // Find shortest path for all vertices
    for (int count = 0; count < V - 1; count++) {
        // Pick the minimum distance vertex from the set of vertices not yet processed.
        int u = minDistance(dist, visited);

        // Mark the picked vertex as processed
        visited[u] = true;

        // Update dist value of the adjacent vertices of the picked vertex
        for (int v = 0; v < V; v++) {
            // Update dist[v] only if:
            // 1. It is not visited yet
            // 2. There is an edge from u to v
            // 3. Total weight of path from src to v through u is smaller than current dist[v]
            if (!visited[v] && graph[u][v] && dist[u] != INT_MAX 
                && dist[u] + graph[u][v] < dist[v]) {
                
                parent[v] = u;
                dist[v] = dist[u] + graph[u][v];
            }
        }
    }

    // Print the output for the requested destination
    printf("\n--- Routing Results ---\n");
    if (dist[dest] == INT_MAX) {
        printf("No path exists between %d and %d\n", src, dest);
    } else {
        printf("Source Node:      %d\n", src);
        printf("Destination Node: %d\n", dest);
        printf("Total Cost/Dist:  %d\n", dist[dest]);
        printf("Shortest Path:    ");
        printPath(parent, dest);
        printf("\n");
    }
}

int main() {
    /* Let us create the following weighted graph
          (1)---8---(2)---7---(3)
         /  |         |         \
       4/   |11       |2         \9
       /    |         |           \
     (0)---8---(7)---(8)---6---(4)
       \       /  \   |       /
       8\    1/   6\  |7    2/
         \   /      \ |     /
          (6)---1---(5)----/ 
          
       0 means no direct edge between the nodes.
    */
    int graph[V][V] = {
        { 0, 4, 0, 0, 0, 0, 0, 8, 0 },
        { 4, 0, 8, 0, 0, 0, 0, 11, 0 },
        { 0, 8, 0, 7, 0, 4, 0, 0, 2 },
        { 0, 0, 7, 0, 9, 14, 0, 0, 0 },
        { 0, 0, 0, 9, 0, 10, 0, 0, 0 },
        { 0, 0, 4, 14, 10, 0, 2, 0, 0 },
        { 0, 0, 0, 0, 0, 2, 0, 1, 6 },
        { 8, 11, 0, 0, 0, 0, 1, 0, 7 },
        { 0, 0, 2, 0, 0, 0, 6, 7, 0 }
    };

    int src, dest;
    printf("\n=================================\n");
    printf("   DIJKSTRA'S SHORTEST PATH\n");
    printf("=================================\n");
    printf("Graph contains nodes 0 through 8.\n");
    
    printf("Enter Source Node (0-8): ");
    scanf("%d", &src);
    
    printf("Enter Destination Node (0-8): ");
    scanf("%d", &dest);

    if (src < 0 || src > 8 || dest < 0 || dest > 8) {
        printf("Invalid nodes entered.\n");
        return 1;
    }

    dijkstra(graph, src, dest);

    return 0;
}