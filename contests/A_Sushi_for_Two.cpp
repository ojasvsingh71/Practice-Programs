#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
        int n;
        cin>>n;
        vector<int> nums(n);
        vector<int> prefix(n,1),suffix(n,1);
        for(int i=0;i<n;i++){
            cin>>nums[i];
            if(i>0){
                if(nums[i]==nums[i-1]){
                    prefix[i]+=prefix[i-1];
                }
            }
        }
        for(int i=n-2;i>=0;i--){
            if(nums[i]==nums[i+1]){
                suffix[i]+=suffix[i+1];
            }
        }
        int ans=0;
        for(int i=1;i<n;i++){
            if(nums[i]!=nums[i-1]){
                ans=max(ans,min(prefix[i],suffix[i-1]));
                ans=max(ans,min(prefix[i-1],suffix[i]));
            }
        }
        cout<<ans*2<<"\n";
    
    
    return 0;
}
