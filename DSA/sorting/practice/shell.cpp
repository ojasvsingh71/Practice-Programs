#include <bits/stdc++.h>
using namespace std;

void shell(int n,vector<int>& nums){
    for(int gap=n/2;gap>=1;gap/=2){
        for(int j=gap;j<n;j++){
            for(int i=j-gap;i>=0;i-=gap){
                if(nums[i+gap]<nums[i]) swap(nums[i],nums[i+gap]);
            }
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

    shell(n,nums);

    for(int i=0;i<n;i++) cout<<nums[i]<<" ";

    return 0;
}
