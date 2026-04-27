#include <bits/stdc++.h>
using namespace std;

bool isSafe(int pos,int k,vector<vector<int>>& graph,vector<int> path){
    if(!graph[path[pos-1]][k]) return false;
    for(int i=0;i<pos;i++){
        if(path[i]==k) return false;
    }
    return true;
}

bool solve(int n,vector<vector<int>>& graph,vector<int> path,int i){
    if(i==n){
        if(!graph[path[n-1]][path[0]]) return false;
        for(int i:path){
            cout<<i<<" ";
        }cout<<path[0]<<"\n";
        return true;
    }

    
        for(int k=1;k<n;k++){
            if(isSafe(i,k,graph,path)){
                path[i]=k;
                if(solve(n,graph,path,i+1)) return true;
                path[i]=-1;
            }
        
    }return false;
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n;
    cin>>n;
    vector<vector<int>> graph(n,vector<int>(n));
    for(int i=0;i<n;i++){
        for(int j=0;j<n;j++){
            cin>>graph[i][j];
        }
    }

    vector<int> path(n,-1);
    path[0]=0;

    if(!solve(n,graph,path,1)){
        cout<<"Solution does not exist\n";
    }
    
    return 0;
}
