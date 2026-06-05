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
        long long sum=0;
        long long ans=INT_MAX;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            sum+=nums[i];
            ans=min(ans,sum/(i+1));
            cout<<ans<<" ";
        }
        cout<<"\n";

    }
    
    return 0;
}
