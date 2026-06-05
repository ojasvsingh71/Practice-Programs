#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n;
    long long d;
    cin>>n>>d;
    vector<long long> nums(n);
    for(int i=0;i<n;i++) cin>>nums[i];

    sort(nums.rbegin(),nums.rend());
    int ans=0;
    int i=0;
    int t=n;
    while(i<n && t>0){
        long long req=(d+1)/nums[i];    
        if((d+1)%nums[i]!=0) req++;
        if(req<=t){
            ans++;
        }t-=req;
        i++;
    }
    cout<<ans<<"\n";

    
    return 0;
}
