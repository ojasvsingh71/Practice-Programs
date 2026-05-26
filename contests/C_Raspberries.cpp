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
        vector<int>nums(n);
        int ans=INT_MAX;
        int odd=0,even=0;
        for(int i=0;i<n;i++) {
            cin>>nums[i];
            if(nums[i]%k==0){
                ans=0;
            }else {
                ans=min(ans,k-nums[i]%k);
            }
            if(nums[i]%2==0) even++;
            else odd++;
        }

        if(k==4){
            if(even>1) ans=0;
            else if(even==1 && odd>0) ans=min(ans,1);
            else if(odd>1) ans=min(ans,2); 
        }
        cout<<ans<<"\n";

        
    }
    
    return 0;
}
