#include <bits/stdc++.h>
using namespace std;

vector<int_least16_t> memo;

int solve(int n,vector<int>& prices){
    if(n==0) return 0;
    if(memo[n]!=-1) return memo[n];

    int ans=0;
    for(int i=1;i<=n;i++){
        ans=max(ans,prices[i-1]+solve(n-i,prices));
    }
    return memo[n]=ans;
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n;
    cin>>n;
    vector<int> prices(n);
    for(int i=0;i<n;i++) cin>>prices[i];

    memo.resize(n+1,-1);

    cout<<solve(n,prices);
    
    return 0;
}



// 4
// 2 5 7 8