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
        long long sum=0;
        int bu=0;
        for(int i=0;i<n;i++) {
            cin>>nums[i];
            sum+=nums[i];
            if(sum<(i+1)*(i+2)/2) bu=1;
        }
        if(bu) cout<<"NO\n";
        else cout<<"YES\n";
    }
    
    return 0;
}
