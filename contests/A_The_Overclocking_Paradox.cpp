#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n;
        long long k,h;
        cin>>n>>k>>h;

        vector<long long> nums(n);
        long long mini=LLONG_MAX;
        for(int i=0;i<n;i++) {
            cin>>nums[i];
            mini=min(mini,nums[i]);
        }

        if(mini+k<=h) cout<<mini+k<<"\n";
        else cout<<h<<"\n";


    }
    
    return 0;
}
