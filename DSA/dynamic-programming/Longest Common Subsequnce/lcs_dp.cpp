#include <bits/stdc++.h>
using namespace std;

string a,b;
vector<vector<int>> dp;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    cin>>a>>b;
    dp.resize(a.size()+1,vector<int>(b.size()+1,0));
    for(int i=1;i<=a.size();i++){
        for(int j=1;j<=b.size();j++){
            if(a[i-1]==b[j-1]){
                dp[i][j]=1+dp[i-1][j-1];
            }else dp[i][j]=max(dp[i-1][j],dp[i][j-1]);
        }
    }
    cout<<dp[a.size()][b.size()];
    
    return 0;
}
