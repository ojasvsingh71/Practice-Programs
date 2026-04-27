#include <bits/stdc++.h>
using namespace std;

vector<vector<int>> memo;

int knapsack(int i,int w,vector<int>& values,vector<int>& weight){
    if(i==0){
        if(weight[i]<=w) return values[i];
        return 0;
    }
    if(memo[i][w]!=-1) return memo[i][w];

    int notake=knapsack(i-1,w,values,weight);

    int take=0;
    if(weight[i]<=w){
        take=values[i]+knapsack(i-1,w-weight[i],values,weight);
    }
    return memo[i][w]=max(take,notake);
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n,w;
    cin>>n>>w;
    vector<int> values(n),weight(n);

    memo.resize(n+1,vector<int>(w+1,-1));

    for(int i=0;i<n;i++) cin>>values[i];
    for(int i=0;i<n;i++) cin>>weight[i];
    
    cout<<knapsack(n-1,w,values,weight);

    return 0;
}


// 3
// 4
// 1 2 3
// 4 5 1