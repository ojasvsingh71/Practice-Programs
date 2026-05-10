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
        long long mid=0;
        for(int i=0;i<n;i++) {
            cin>>nums[i];
            mid+=nums[i];
        }
        mid/=n;
        for(int i=0;i<n;i++){
            int start=nums[i];
            int small=0,large=0;
            for(int j=i+1;j<n;j++){
                if(nums[j]>nums[i]) small++;
                else if(nums[j]<nums[i]) large++;
            }
            cout<<max(small,large)<<" ";
        }
        cout<<"\n";


    }
    
    return 0;
}
