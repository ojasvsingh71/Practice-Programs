#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n,wt,c;
    cin>>n>>wt>>c;
    vector<int> values(n),weight(n);

    for(int i=0;i<n;i++) cin>>weight[i]>>values[i];

    vector<vector<vector<int>>> dp(n+1,vector<vector<int>>(wt+1,vector<int>(c+1,0)));

    for(int i=1;i<=n;i++){
        for(int w=0;w<=wt;w++){
            for(int co=0;co<=c;co++){
                dp[i][w][co]=dp[i-1][w][co];

                if(weight[i-1]<=w && co>0){
                    dp[i][w][co]=max(dp[i][w][co],values[i-1]+dp[i-1][w-weight[i-1]][co-1]);
                }
            }
        }
    }
    
    cout<<dp[n][wt][c];

    return 0;
}
