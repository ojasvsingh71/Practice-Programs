#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n;
        unsigned long long c;
        long long k;
        cin>>n>>c>>k;
        vector<long long> nums(n);
        
        for(int i=0;i<n;i++){
            cin>>nums[i];
        }
        sort(nums.begin(),nums.end());
        for(int i=0;i<n;i++){
            if(nums[i]>c) continue;
            else{
                long long diff=c-nums[i];
                if(diff<=k){
                    nums[i]=c;
                    k-=diff;
                }else{
                    nums[i]+=k;
                    k=0;
                }c+=nums[i];
            }
        }
        cout<<c<<"\n";

        
    }
    
    return 0;
}
