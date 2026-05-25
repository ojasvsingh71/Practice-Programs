#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int v;
    cin>>v;
    int e;
    cin>>e;
    vector<vector<pair<int,int>>> graph(v);
    for(int i=0;i<e;i++){
        int u,v,w;
        cin>>u>>v>>w;
        graph[u].push_back({w,v});
        graph[v].push_back({w,v});
    }

    priority_queue<pair<int,int>,vector<pair<int,int>>,greater<pair<int,int>>> pq;
    vector<int> dist(v,INT_MAX);
    int src;
    cin>>src;
    dist[src]=0;
    pq.push({0,src});
    while(!pq.empty()){
        int curr=pq.top().second;

        pq.pop();
        for(auto i:graph[curr]){
            int v=i.second;
            int w=i.first;
            if(dist[v]>dist[curr]+w){
                dist[v]=dist[curr]+w;
                pq.push({dist[v],v});
            }

        }
    }
    
    for(int i=0;i<v;i++){
        cout<<i<<" "<<dist[i]<<"\n";
    }

    return 0;
}
