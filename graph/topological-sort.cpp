// You are given a Directed Acyclic Graph (DAG) in the form of 
//  vertices and 
//  directed edges.

// Your task is to perform a topological sort of the graph using Kahn’s Algorithm (BFS-based). If there are multiple nodes with in-degree 0 at any step, always choose the node with the smallest index first.

// Input Format:

// The first line contains two space-separated integers 
//  and 
//  - the number of vertices and the number of directed edges.
// The next 
//  lines each contain two space-separated integers 
//  and 
// , indicating a directed edge from vertex 
//  to vertex 
// .


// Output Format:

// Print a single line with the lexicographically smallest topological ordering of the graph.
// If no such ordering exists (i.e., the graph contains a cycle), print:
// Cycle detected


// Constraints:

// The graph does not contain self-loops or multiple edges between the same pair of vertices.


// Sample Test Case:

// Input:
// 6 6
// 5 2
// 5 0
// 4 0
// 4 1
// 2 3
// 3 1

// Output:
// 4 5 0 2 3 1 

// Explanation:
// At the start, vertices 4 and 5 have an in-degree of 0.
// Since 4 < 5, 4 is chosen first.
// This process continues, always choosing the smallest available node to maintain lexicographical order.


#include<bits/stdc++.h>
using namespace std;

int main(){
    int V,e;
    cin>>V>>e;
    map<int,vector<int>> edges;
    vector<int> indegree(V,0);
    for(int i=0;i<e;i++){
        int u,v;
        cin>>u>>v;
        edges[u].push_back(v);
        indegree[v]++;
    }
    vector<int> ans;
    queue<int> q;
    for(int i=0;i<V;i++){
        if(indegree[i]==0){
            ans.push_back(i);
            indegree[i]--;
            q.push(i);
        }
    }
    // bfs
    while(!q.empty()){
        int curr=q.front();
        q.pop();
        for(int i:edges[curr]){
            indegree[i]--;
            if(indegree[i]==0){
                q.push(i);
                ans.push_back(i);
            }
        }
    }

    for(int i:ans) cout<<i<<" ";
}