#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        vector<int> nums(7);
        cin>>nums[0]>>nums[1]>>nums[2]>>nums[3]>>nums[4]>>nums[5]>>nums[6];
        sort(nums.begin(),nums.end());
        int sum=0;
        for(int i=0;i<6;i++){
            sum-=nums[i];
        }
        cout<<sum+nums[6]<<"\n";

    }
    
    return 0;
}
