#include <bits/stdc++.h>
using namespace std;

long long cnt=0;

void ways(vector<int>& nums,int sum){
    vector<long long> dp(sum+1,0);
    dp[0]=1;

    for(int i=0;i<nums.size();i++){
        for(int j=nums[i];j<=sum;j++){
            dp[j]+=dp[j-nums[i]];
        }
    }
    cnt=dp[sum];
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int sum,n;
    cin>>sum>>n;
    vector<int> nums(n);
    for(int i=0;i<n;i++){
        cin>>nums[i];
    }
    
    ways(nums,sum);

    cout<<cnt;

    return 0;
}
