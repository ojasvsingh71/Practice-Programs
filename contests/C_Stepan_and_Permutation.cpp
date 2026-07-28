#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n,x,y;
        cin>>n>>x>>y;
        // int even=0,odd=0;
        vector<int> nums(n);
        int bu=0;
        int g=__gcd(x,y);
        for(int i=0;i<n;i++){
            cin>>nums[i];
            if(abs(nums[i]-(i+1))%g!=0) bu=1;
        }
        if(bu) cout<<"NO\n";
        else cout<<"YES\n";
        
    }
    
    return 0;
}
