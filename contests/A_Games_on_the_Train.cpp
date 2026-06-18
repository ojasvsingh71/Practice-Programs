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
        int mini=INT_MAX,maxi=INT_MIN;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            mini=min(mini,nums[i]);
            maxi=max(maxi,nums[i]);
        }
        cout<<maxi-mini+1<<"\n";
    }

    
    return 0;
}
