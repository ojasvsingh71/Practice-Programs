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
        int maxi=-1;
        int bu=-1;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            if(nums[i]>maxi){
                maxi=nums[i];
                bu=i;
            }
        }
        swap(nums[0],nums[bu]);
        for(int i:nums){
            cout<<i<<" ";
        }cout<<"\n";
    }
    
    return 0;
}
