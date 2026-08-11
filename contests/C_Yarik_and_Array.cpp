#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n;
        cin>>n;
        vector<int> nums(n);
        vector<long long> dp(n,0);
        for(int i=0;i<n;i++){
            cin>>nums[i];
            if(i==0) dp[i]=nums[i];
            else{
                if(abs(nums[i-1])%2==abs(nums[i])%2) dp[i]=nums[i];
                else {
                    if(dp[i-1]<0) dp[i]=nums[i];
                    else{
                        dp[i]=max(dp[i-1]+nums[i],(1ll)*nums[i]);
                    }
                }
            }
            // cout<<dp[i]<<" ";
        }
        // cout<<"\t";
        cout<<*max_element(dp.begin(),dp.end())<<"\n";

    }
    
    return 0;
}
