#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        string a,b;
        cin>>a>>b;

        int n=a.size(),m=b.size();
        vector<vector<int>> dp(n+1,vector<int>(m+1,0));
        int ans=0;
        for(int i=1;i<=n;i++){
            for(int j=1;j<=m;j++){
                if(a[i-1]==b[j-1]){
                    dp[i][j]=1+(dp[i-1][j-1]);
                    ans=max(ans,dp[i][j]);
                }
            }
        }
        cout<<n+m-2*ans<<"\n";

    }
    
    return 0;
}
