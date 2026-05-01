#include <bits/stdc++.h>
using namespace std;

bool isSafe(int col,int node,vector<vector<int>>& nums,vector<int>& color){
    for(int i=0;i<nums.size();i++){
        if(nums[node][i]){
            if(color[i]==col) return false;
        }
    }return true;
}

void solve(int n,int m,int node,vector<vector<int>>& nums,vector<int>& color){
    if(node==n){
        cout<<"\n";
        for(int i=0;i<n;i++){
            cout<<color[i]<<" ";
        }cout<<"\n";
        return ;
    }
    for(int i=0;i<m;i++){
        if(isSafe(i,node,nums,color)){
            color[node]=i;
            solve(n,m,node+1,nums,color);
            color[node]=-1;
        }
    }
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n,m;
    cin>>n>>m;
    vector<vector<int>> nums(n,vector<int>(n));

    for(int i=0;i<n;i++){
        for(int j=0;j<n;j++){
            cin>>nums[i][j];
        }
    }

    vector<int> color(n,-1);

    solve(n,m,0,nums,color);
    
    return 0;
}
