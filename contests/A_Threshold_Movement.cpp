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
        for(int i=0;i<n;i++){
            cin>>nums[i];
        }
        if(n%2==1) {
            cout<<"NO\n";
            continue;
        }
        int bu=0;
        int low=nums[1]+1,high=nums[0]-1;
        for(int i=0;i<n;i+=2){
            // if(low<nums[i+1] || high>nums[i]){
            //     bu=1;
            //     break;
            // }
            low=max(low,nums[i+1]+1);
            high=min(high,nums[i]-1);
            if(low>high) {
                bu=1;
                break;
            }
            // cout<<low<<" "<<high<<" - ";
        }
        if(bu) cout<<"NO\n";
        else cout<<"YES\n";
    }
    
    return 0;
}
