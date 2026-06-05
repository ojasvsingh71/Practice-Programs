#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n;
        long long x;
        cin>>n>>x;
        vector<long long> nums(n);
        long long maxi=-1,mini=-1; 
        int ans=0;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            if(i==0){
                maxi=nums[i]+x;
                mini=nums[i]-x;
            }else{
                if(abs(nums[i]-maxi)<=x || abs(nums[i]-mini)<=x) continue;
                else{
                    ans++;
                    maxi=nums[i]+x;
                    mini=nums[i]-x;
                }
            }
        } 
        cout<<ans<<"\n";
    }
    
    return 0;
}
