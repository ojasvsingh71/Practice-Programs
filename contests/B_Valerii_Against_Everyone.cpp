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
        unordered_map<int,int> freq;
        for(int i=0;i<n;i++) {
            cin>>nums[i];
            if(freq[nums[i]]){
                bu=1;
            }
            freq[nums[i]]++;
        }

        if(bu) cout<<"YES\n";
        else cout<<"NO\n";
    }
    
    return 0;
}
