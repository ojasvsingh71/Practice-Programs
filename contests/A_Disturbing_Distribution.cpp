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
        int one=1;
        for(int i=0;i<n;i++) {
            cin>>nums[i];
            if(nums[i]!=1) one=0;
        }
        
        long long ans=0;
        for(int i=n-1;i<n;i++){
            if(nums[i]==1){
                for(int j=i;j>=0;j--){
                    if(nums[j]>1) {
                        one=1;
                        break;
                    }
                }
                break;
            }
        }
        for(int i:nums){
            if(i!=1) ans+=i;
        }
        cout<<ans+one<<"\n";
        
    }
    
    return 0;
}
