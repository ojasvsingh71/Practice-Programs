#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n,m;
    cin>>n>>m;
    int limit;
    cin>>limit;

    vector<vector<int>> graph(n,vector<int>(m));
    for(int i=0;i<n;i++){
        for(int j=0;j<m;j++){
            cin>>graph[i][j];
        }
    }

    deque<pair<int,int>> dq;
    vector<vector<int>> dist(n,vector<int>(m,INT_MAX));
    dist[0][0]=graph[0][0];
    dq.push_back({0,0});

    vector<int> dx={-1,1,0,0};
    vector<int> dy={0,0,-1,1};

    while(!dq.empty()){
        int i=dq.front().first;
        int j=dq.front().second;
        dq.pop_front();

        for(int k=0;k<4;k++){
            int x=i+dx[k];
            int y=j+dy[k];

            if(x>n-1 || x<0 || y<0 || y>m-1) continue;

            int w=graph[x][y];
            if(dist[x][y]>w+dist[i][j]){
                dist[x][y]=w+dist[i][j];
                
                if(w==0){
                    dq.push_front({x,y});
                }else{
                    dq.push_back({x,y});
                }
            }
        }
    }
    cout<<(dist[n-1][m-1]<limit)<<"\n";
    
    return 0;
}






// 6 6 4
// 0 1 0 1 0 0
// 0 1 0 1 1 0
// 0 0 0 0 1 0
// 1 1 1 0 1 0
// 0 0 0 0 0 0
// 0 1 1 1 1 0