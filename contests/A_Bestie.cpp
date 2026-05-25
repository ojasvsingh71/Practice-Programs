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
        cin>>nums[0];
        long long g=nums[0]; 
        for(int i=1;i<n;i++) {
            cin>>nums[i];
            g=__gcd(g,nums[i]);
        }
        if(g==1){
            cout<<0<<"\n";
        }else{
            vector<long long> gu(n);
            for(int i=0;i<n;i++){
                gu[i]=__gcd(nums[i],(long long)i+1);
            }
            // for(int i:gu) cout<<i<<" ";
            // cout<<"\n";
            long long ans=INT_MAX;
            for(int i=n-1;i>=0;i--){
                long long curr=0;
                long long hu=g;
                for(int j=i;j>=0;j--){
                    hu=__gcd(hu,gu[j]);
                    curr+=n-j;
                    // cout<<hu<<" ";
                    if(hu==1){
                        ans=min(ans,curr);
                        break;
                    }
                }
                // cout<<curr<<"\n";
            }
            cout<<ans<<"\n";
        }


    }
    
    return 0;
}
