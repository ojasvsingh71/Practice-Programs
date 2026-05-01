#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n;
    cin>>n;
    vector<int> prices(n);
    for(int i=0;i<n;i++) cin>>prices[i];
    
    vector<int>dp(n+1,0);
    for(int i=1;i<=n;i++){
        for(int cut=1;cut<=i;cut++){
            dp[i]=max(dp[i],prices[cut-1]+dp[i-cut]);
        }
    }
    cout<<dp[n];

    return 0;
}


// 4
// 2 5 7 8