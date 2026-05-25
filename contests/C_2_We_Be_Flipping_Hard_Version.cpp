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
        vector<long long> nums(n);

        vector<int> prefix(n,0);
        for(int i=0;i<n;i++) {
            cin>>nums[i];
            prefix[i]=abs(nums[i]);
            if(i>0) prefix[i]+=prefix[i-1];
        }
        vector<int> bu;
        int ans;
        for(int i=0;i<n;i++){
            

        }


    }
    
    return 0;
}
