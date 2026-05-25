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
        int maxi=INT_MIN;
        int mini=INT_MAX;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            maxi=max(maxi,nums[i]);
            mini=min(mini,nums[i]);
        }

        int ans=(maxi-mini)/2;
        ans+=(maxi-mini)%2;

        cout<<ans<<"\n";
    }
    
    return 0;
}
