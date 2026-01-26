// A Bipartite Graph is a graph whose vertices can be divided into two independent sets, 
//  and 
//  such that every edge (
// , 
// ) either connects a vertex from 
//  to 
//  or a vertex from 
//  to 
// . In other words, for every edge (
// , 
// ), either 
//  belongs to 
//  and 
//  to 
// , or 
//  belongs to 
//  and 
//  to 
// . We can also say that there is no edge that connects vertices of the same set.



// Write a program to determine whether a given graph is bipartite or not.



// Input format:

// The first line of input contains an integer num_vertices, indicating the number of vertices in the graph.
// The next num_vertices lines represent the adjacency matrix of the graph. Each line contains num_vertices space-separated integers (0 or 1), representing the adjacency matrix row-wise.
// The last line contains an integer source_vertex, representing the source vertex for checking bipartiteness.


// Output format:

// If the graph is bipartite, output "Yes". Otherwise, output "No".

// Test case 1
// 4	
// 0 1 0 1	
// 1 0 1 0	
// 0 1 0 1	
// 1 0 1 0	
// 0	
// Yes

#include<bits/stdc++.h>
using namespace std;

int main(){
    int n;
    cin>>n;
    vector<vector<int>> graph(n,vector<int>(n,0));
    for(int i=0;i<n;i++){
        for(int j=0;j<n;j++){
            cin>>graph[i][j];
        }
    }
    vector<int> color(n,-1);
    int start;
    cin>>start;
    queue<int> q;
    color[start]=1;
    q.push(start);
    while(!q.empty()){
        int curr=q.front();
        q.pop();
        for(int i=0;i<n;i++){
            if(graph[curr][i]){
                if(color[i]==-1){
                    color[i]=1-color[curr];
                    q.push(i);
                }else{
                    if(color[i]==color[curr]){
                        cout<<"No\n";
                        return 0;
                    }
                }
            }
        }
    }cout<<"Yes\n";

}