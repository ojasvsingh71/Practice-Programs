#include <bits/stdc++.h>
using namespace std;

int solve(int n,vector<int>& nums){
    if(n==0) return 0;
    int ans=0;
    for(int i=1;i<=n;i++){
        ans=max(ans,nums[i-1]+solve(n-i,nums));
    }return ans;
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n;
    cin>>n;
    vector<int> nums(n);
    for(int i=0;i<n;i++) cin>>nums[i];

    cout<<solve(n,nums);
    
    return 0;
}




// 4
// 2 5 7 8
