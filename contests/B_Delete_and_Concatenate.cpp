#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n,c;
        cin>>n>>c;
        vector<int> nums(n);
        for(int i=0;i<n;i++){
            cin>>nums[i];
        }
        sort(nums.begin(),nums.end());
        long long ans=0;
        
        int far=0;
        while(far<n && nums[far]<c) far++;
        
        if(far>n/2){
            far=n/2;
        }
            int limit=n;
            for(int i=0;i<far;i++){
                ans+=nums[n-1-i]-c;
                limit=n-1-i;
            }
            for(int i=far;i<limit;i++){
                ans+=nums[i]-c;
            }
        // cout<<far<<"--"<<limit<<" ";
        
        cout<<ans<<"\n";
    }
    
    return 0;
}
