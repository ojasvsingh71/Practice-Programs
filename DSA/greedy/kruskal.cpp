#include <bits/stdc++.h>
using namespace std;

struct edge{
    int u,v,w;
};

vector<int> parent;
vector<int> ranku;

int findparent(int u){
    if(parent[u]==u) return u;
    return findparent(parent[u]);
}

void uni(int u,int v){
    int setu=findparent(u);
    int setv=findparent(v);

    if(ranku[setu]>ranku[setv]){
        parent[setv]=setu;
        ranku[setu]++;
    }else{
        parent[setu]=setv;
        ranku[setv]++;
    }
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int V;
    cin>>V;
    int e;
    cin>>e;
    parent.resize(V);
    ranku.resize(V,0);

    for(int i=0;i<V;i++) parent[i]=i;

    vector<edge> edges(e);
    for(int i=0;i<e;i++){
        cin>>edges[i].u>>edges[i].v>>edges[i].w;
    }

    sort(edges.begin(),edges.end(),[](const auto&a,const auto &b){
        return a.w<b.w;
    });

    int ans=0;
    for(int i=0;i<e;i++){
        int u=edges[i].u;
        int v=edges[i].v;
        int w=edges[i].w;

        int setu=findparent(u);
        int setv=findparent(v);
        if(setu!=setv){
            cout<<u<<" "<<v<<" "<<w<<"\n";
            uni(u,v);
            ans+=w;
        }
    }

    cout<<ans;
    
    return 0;
}
