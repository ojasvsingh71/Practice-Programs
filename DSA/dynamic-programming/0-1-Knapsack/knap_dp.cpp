#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n,w;
    cin>>n>>w;
    vector<int> values(n),weight(n);

    for(int i=0;i<n;i++) cin>>values[i];
    for(int i=0;i<n;i++) cin>>weight[i];

    vector<vector<int>> dp(n,vector<int>(w+1,0));

    for(int ww=weight[0];ww<=w;ww++){
        dp[0][ww]=values[0];
    }

    for(int i=1;i<n;i++){
        for(int ww=0;ww<=w;ww++){
            int notake=dp[i-1][ww];
            int take=0;
            if(weight[i]<=ww){
                take=values[i]+dp[i-1][ww-weight[i]];
            }
            dp[i][ww]=max(take,notake);
        }
    }
    
    cout<<dp[n-1][w];

    return 0;
}


// 3
// 4
// 1 2 3
// 4 5 1