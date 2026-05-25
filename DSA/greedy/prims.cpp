#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n;
    cin>>n;
    vector<vector<int>> graph(n,vector<int>(n));
    for(int i=0;i<n;i++){
        for(int j=0;j<n;j++) cin>>graph[i][j];
    }

    priority_queue<pair<int,int>,vector<pair<int,int>>,greater<pair<int,int>>> pq;
    pq.push({0,0});
    vector<int> inmst(n,0);
    
    vector<int> keys(n,INT_MAX);
    int ans=0;
    keys[0]=0;
    while(!pq.empty()){
        int curr=pq.top().second;
        pq.pop();
        if(inmst[curr]) continue;
        inmst[curr]=1;
        ans+=keys[curr];
        for(int i=0;i<n;i++){
            if(!inmst[i] && graph[curr][i] && keys[i]>graph[curr][i]){
                keys[i]=graph[curr][i];
                pq.push({keys[i],i});
            }
        }

    }
    cout<<ans;
    
    return 0;
}
