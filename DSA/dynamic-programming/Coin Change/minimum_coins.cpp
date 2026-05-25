#include <bits/stdc++.h>
using namespace std;

int cnt=0;

void mini_coins(vector<int>& nums,int tar){
    vector<int> dp(tar+1,INT_MAX);
    dp[0]=0;

    for(int i:nums){
        for(int j=i;j<=tar;j++){
            dp[j]=min(dp[j],dp[j-i]+1);
        }
    }

    cnt=dp[tar];
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    
    int tar,n;
    cin>>tar>>n;
    vector<int> nums(n);
    for(int i=0;i<n;i++){
        cin>>nums[i];
    }
    
    mini_coins(nums,tar);

    cout<<cnt;
    
    return 0;
}
