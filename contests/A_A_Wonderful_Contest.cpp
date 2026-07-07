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
        int bu=0;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            if(nums[i]==100) bu=1;
        }
        if(bu) cout<<"Yes\n";
        else cout<<"No\n";
    }
    
    return 0;
}
