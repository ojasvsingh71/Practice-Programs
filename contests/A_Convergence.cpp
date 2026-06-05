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
        sort(nums.begin(),nums.end());

        int ls=0,rs=n-1;
        int ans=0;
        while(ls<rs){
            if(nums[ls]==nums[rs]) break;
            ans++;
            ls++;
            rs--;
        }
        cout<<ans<<"\n";
    }
    
    return 0;
}
