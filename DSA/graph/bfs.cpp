#include<bits/stdc++.h>
using namespace std;

void bfs(unordered_map<int,vector<int>> &edges,vector<int> &vis,int u){
    vis[u]=1;
    queue<int> q;
    q.push(u);
    while(!q.empty()){
        int curr=q.front();
        q.pop();
        cout<<curr<<" ";
        for(int i:edges[curr]){
            if(!vis[i]) {
                vis[i]=1;
                q.push(i);
            }
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
    bfs(edges,vis,start);
}