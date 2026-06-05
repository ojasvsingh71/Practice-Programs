#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n;
        long long k,q;
        cin>>n>>k>>q;
        vector<long long>nums(n);
        vector<int> prev(n,0);
        vector<int> actual(n,0);
        long long ans=0;

        for(int i=0;i<n;i++){
            cin>>nums[i];
            if(nums[i]<=q){
                if(i>0){
                    prev[i]+=prev[i-1];
                }prev[i]++;
                if(prev[i]>=k){
                    actual[i]++;
                    if(i>0){
                        actual[i]+=actual[i-1];
                    }
                }
            }
        }
        for(int i:actual){
            ans+=i;
        }
        cout<<ans<<"\n";

    }
    
    return 0;
}
