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
        int maxi=0;
        vector<int> nums(n);
        int ans=0;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            maxi=max(maxi,nums[i]);
            if(maxi>nums[i]) ans++;
        }
        cout<<ans<<"\n";
    }
    
    return 0;
}
