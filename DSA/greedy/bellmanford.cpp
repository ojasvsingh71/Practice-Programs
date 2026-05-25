#include <bits/stdc++.h>
using namespace std;

struct edge{
    int u,v,w;
};

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int v;
    cin>>v;
    int e;
    cin>>e;
    vector<edge> edges(e);
    for(int i=0;i<e;i++) cin>>edges[i].u>>edges[i].v>>edges[i].w;
    
    vector<int> dist(v,INT_MAX);

    int src;
    cin>>src;
    dist[src]=0;
    for(int i=0;i<v-1;i++){
        for(int j=0;j<e;j++){
            int u=edges[j].u;
            int v=edges[j].v;
            int w=edges[j].w;

            if(dist[u]!=INT_MAX && dist[v]>dist[u]+w){
                dist[v]=dist[u]+w;
            }
        }
    }

    int bu=0;
    for(int j=0;j<e;j++){
        int u=edges[j].u;
        int v=edges[j].v;
        int w=edges[j].w;

        if(dist[u]!=INT_MAX && dist[v]>dist[u]+w){
            bu=1;
            break;
        }
    }

    if(bu) cout<<-1<<"\n";
    else{
        for(int i=0;i<v;i++) cout<<i<<" "<<dist[i]<<"\n";
    }

    
    return 0;
}







// 4	
// 5	
// 0 1 4	
// 0 2 5	
// 1 2 -3	
// 1 3 6	
// 2 3 2	
// 0