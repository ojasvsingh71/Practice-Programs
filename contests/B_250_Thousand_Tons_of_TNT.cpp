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

        int maxi=INT_MIN,mini=INT_MAX;
        if(n==1) cout<<0<<"\n";
        else{
            for(int i=1;i<n;i++){
                int diff=abs(nums[i]-nums[i-1]);
                maxi=max(maxi,diff);
                mini=min(mini,diff);
            }
        }
        cout<<maxi-mini<<"\n";
    }
    
    return 0;
}
