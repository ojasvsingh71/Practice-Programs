#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    string a,b,c;
    cin>>a>>b>>c;

    int n=a.size(),m=b.size(),k=c.size();

    vector<vector<vector<int>>> dp(n+1,vector<vector<int>>(m+1,vector<int>(k+1,0)));

    for(int i=1;i<=n;i++){
        for(int j=1;j<=m;j++){
            for(int l=1;l<=k;l++){
                if(a[i-1]==b[j-1] && b[j-1]==c[l-1]){
                    dp[i][j][l]=1+dp[i-1][j-1][l-1];
                }else{
                    dp[i][j][l]=max({dp[i-1][j][l],dp[i][j-1][l],dp[i][j][l-1]});
                }
            }
        }
    }

    cout<<dp[n][m][k];

    
    return 0;
}
