#include<bits/stdc++.h>
using namespace std;

void dfs(unordered_map<int,vector<int>> &edges,vector<int> &vis,int u){
    vis[u]=1;
    cout<<u<<" ";
    for(int i:edges[u]){
        if(!vis[i]){
            vis[i]=1;
            dfs(edges,vis,i);
        }
    }
}

int main(){
    int V,e;
    cin>>V>>e;
    vector<int> vis(V,0);
    unordered_map<int,vector<int>> edges;
    for(int i=0;i<e;i++){
        int u,v;
        cin>>u>>v;
        edges[u].push_back(v);
        edges[v].push_back(u);          // undirected
    }
    int start;
    cin>>start;
    dfs(edges,vis,start);
}