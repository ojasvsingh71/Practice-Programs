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
      
        unordered_set<long long> seen;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            seen.insert(nums[i]);
        }
        long long ans=1;
        while(true){
            if(!seen.count(ans)) break;
            ans*=2;
        }

        cout<<ans<<"\n";

    }
    
    return 0;
}
