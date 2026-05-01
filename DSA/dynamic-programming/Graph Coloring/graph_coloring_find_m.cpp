#include <bits/stdc++.h>
using namespace std;

bool isSafe(int col,vector<int>& color,unordered_map<int,vector<int>> graph,int node){
    for(int i:graph[node]){
        if(col==color[i]) return false;
    }return true;
}

bool solve(int n,int m,int node,unordered_map<int,vector<int>>& graph,vector<int>& color){
    if(node==n) return true;
    for(int i=0;i<m;i++){
        if(isSafe(i,color,graph,node)){
            color[node]=i;
            if(solve(n,m,node+1,graph,color)) return true;
            color[node]=-1;
        }
    }
    return false;
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n,e;
    cin>>n>>e;
    unordered_map<int,vector<int>> graph;

    for(int i=0;i<e;i++){
        int u,v;
        cin>>u>>v;
        graph[u].push_back(v);
        graph[v].push_back(u);
    }

    for(int m=0;m<n;m++){
        vector<int> color(n,-1);
        if(solve(n,m,0,graph,color)) {
            cout<<m<<"\n";
            break;
        }
    }
    
    return 0;
}





// 4 
// 5
// 0 1 
// 1 2
// 1 3
// 2 3
// 3 0