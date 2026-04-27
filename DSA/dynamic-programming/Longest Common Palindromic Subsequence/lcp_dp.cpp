#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    string s;
    cin>>s;

    int n=s.size();

    vector<vector<int>> dp(n+1,vector<int>(n+1,0));
    
    for(int i=0;i<n;i++) dp[i][i]=1;

    for(int len=2;len<=n;len++){
        for(int i=0;i<n-len+1;i++){
            int j=len+i-1;
            if(s[i]==s[j]){
                dp[i][j]=2+(len==2 ? 0 : dp[i+1][j-1]);
            }else{
                dp[i][j]=max(dp[i+1][j],dp[i][j-1]);
            }
        }
    }
    cout<<dp[0][n-1];

    return 0;
}
