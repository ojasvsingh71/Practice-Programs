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
        vector<long long> nums(n);

        for(int i=0;i<n;i++) cin>>nums[i];

        for(int i=1;i<n;i++){
            if(nums[i]<nums[i-1]){
                // long long temp=nums[i];
                nums[i]+=nums[i-1];
                // nums[i-1]=temp;
            }
        }
        // for(long long i:nums) cout<<i<<" ";
        // cout<<"\n";
        cout<<nums[n-1]<<"\n";
    }
    
    return 0;
}
