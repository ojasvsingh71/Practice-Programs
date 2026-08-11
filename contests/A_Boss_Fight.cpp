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
        int limit=-1;
        unordered_map<int,int> freq;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            freq[nums[i]]++;
            if(freq[nums[i]]>n/2+1){
                limit=nums[i];
            }
        }
        int o=n-freq[limit];
        long long ans=0;
        for(int i=0;i<n;i++){
            if(nums[i]==limit) {
                if(o>0) {
                    ans+=nums[i];
                    o--;
                }
            }
            else ans+=nums[i];
        }
        if(limit!=-1) ans+=limit*2;
        cout<<ans<<"\n";
    }
    
    return 0;
}
