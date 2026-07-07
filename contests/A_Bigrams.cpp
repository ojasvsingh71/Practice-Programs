#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int k;
        cin>>k;
        vector<int> nums(k);
        int bu=0,two=0;
        for(int i=0;i<k;i++) {
            cin>>nums[i];
            if(nums[i]>=3) bu=1;
            if(nums[i]==2){
                two++;
                if(two==2) bu=1;
            }
        }
        if(bu) cout<<"YES\n";
        else cout<<"NO\n";

    }
    
    return 0;
}
