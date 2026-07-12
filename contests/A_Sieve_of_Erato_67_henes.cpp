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
        int ss=0;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            if(nums[i]==67) ss++;
        }
        if(ss) cout<<"YES\n";
        else cout<<"NO\n";
    }
    
    return 0;
}
