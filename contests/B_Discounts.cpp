#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n,k;
        cin>>n>>k;
        vector<long long> nums(n),discount(k);
        for(int i=0;i<n;i++) cin>>nums[i];
        for(int i=0;i<k;i++) cin>>discount[i];

        sort(nums.rbegin(),nums.rend());
        sort(discount.begin(),discount.end());

        long long ans=0;
        int i=0;
        int l=0;
        while(i<n){
            if(l==k){
                while(i<n) ans+=nums[i++];
                break;
            }
            for(int j=0;i+j<n && j<discount[l]-1;j++){
                ans+=nums[i+j];
            }
            // cout<<i<<" ";
            i+=discount[l++];
        }
        // cout<<"\n";
        cout<<ans<<"\n";
    }
    
    return 0;
}
