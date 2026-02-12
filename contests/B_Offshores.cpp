#include<bits/stdc++.h>
using namespace std;

int main(){
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int t;
    cin>>t;
    while(t--){
        long long x,y;
        int n;
        cin>>n>>x>>y;
        vector<long long> nums(n);
        long long sum=0;
        vector<long long> chunk(n);
        for(int i=0;i<n;i++) {
            cin>>nums[i];
            chunk[i]=nums[i]/x*y;
            sum+=chunk[i];
        }
        long long ans=0;
        for(int i=0;i<n;i++){
            ans=max(ans,sum-chunk[i]+nums[i]);
        }
        cout<<ans<<"\n";
    }
}