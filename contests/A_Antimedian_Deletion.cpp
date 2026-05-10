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
        for(int i=0;i<n;i++) cin>>nums[i];

        if(n==1) {
            cout<<1<<"\n";
            continue;
        }
        for(int i:nums){
            cout<<2<<" ";
        }cout<<"\n";


    }
    
    return 0;
}
