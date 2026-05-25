#include <bits/stdc++.h>
using namespace std;

void counting(int n,vector<int>& nums){
    int maxi=*max_element(nums.begin(),nums.end());
    int mini=*min_element(nums.begin(),nums.end());

    vector<int> count(-mini+maxi+1,0);
    for(int i:nums){
        count[i-mini]++;
    }

    int k=0;
    for(int i=0;i<count.size();i++){
        while(count[i]>0){
            nums[k++]=i+mini;
            count[i]--;
        }
    }
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n=5;
    // cin>>n;
    vector<int> nums(n);
    nums={5,4,3,2,1};
    // for(int i=0;i<n;i++) cin>>nums[i];

    counting(n,nums);

    for(int i=0;i<n;i++) cout<<nums[i]<<" ";

    return 0;
}
