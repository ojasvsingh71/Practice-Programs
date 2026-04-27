#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    string a,b;

    cin>>a>>b;
    vector<vector<int>> dp(a.size()+1,vector<int>(b.size()+1,0));

    int ans=0;
    for(int i=1;i<=a.size();i++){
        for(int j=1;j<=b.size();j++){
            if(a[i-1]==b[j-1]){
                dp[i][j]=1+dp[i-1][j-1];
                ans=max(ans,dp[i][j]);
            }else dp[i][j]=0;
        }
    }
    
    cout<<ans;

    return 0;
}
