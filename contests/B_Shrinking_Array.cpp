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
        for(int i=0;i<n;i++) cin>>nums[i];

        int ans=INT_MAX;

        if(n==2){
            if(abs(nums[0]-nums[1])<=1) ans=0;
        }

        for(int i=1;i<n-1;i++){
            if(abs(nums[i-1]-nums[i])<=1 || abs(nums[i+1]-nums[i])<=1){
                ans=0;
                break;
            }

            int fst=min({nums[i-1],nums[i],nums[i+1]});
            int thrd=max({nums[i-1],nums[i],nums[i+1]});
            int sec=nums[i]+nums[i-1]+nums[i+1]-fst-thrd;

            if(sec!=nums[i] && fst<=sec && sec<=thrd){
                ans=1;
            }
        }
        if(ans==INT_MAX) ans=-1;
        cout<<ans<<"\n";
    }
    
    return 0;
}
