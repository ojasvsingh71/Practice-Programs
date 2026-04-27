#include <bits/stdc++.h>
using namespace std;

int knapsack(int i,int w,vector<int>& weight,vector<int>& values){
    if(i==0){
        if(weight[i]<=w) return values[i];
        return 0;
    }
    
    int notake=knapsack(i-1,w,weight,values);

    int take=0;
    if(weight[i]<=w){
        take=values[i]+knapsack(i-1,w-weight[i],weight,values);
    }
    return max(take,notake);

}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n,w;
    cin>>n>>w;
    vector<int> weight(n),values(n);

    for(int i=0;i<n;i++) cin>>values[i];
    for(int i=0;i<n;i++) cin>>weight[i];

    cout<<knapsack(n-1,w,weight,values);
    
    return 0;
}



// 3
// 4
// 1 2 3
// 4 5 1