#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n;
    cin>>n;
    vector<int> p(n);
    for(int i=0;i<n;i++) cin>>p[i];

    vector<vector<int>> dp(n,vector<int>(n,INT_MAX));

    for(int i=0;i<n;i++) dp[i][i]=0;

    for(int len=2;len<n;len++){
        for(int i=1;i<n-len+1;i++){
            int j=i+len-1;
            for(int k=i;k<j;k++){
                dp[i][j]=min(dp[i][j],dp[i][k]+dp[k+1][j]+p[i-1]*p[k]*p[j]);
            }
        }
    }
    cout<<dp[1][n-1];
    
    return 0;
}
