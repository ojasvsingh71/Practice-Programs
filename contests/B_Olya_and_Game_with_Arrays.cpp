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
        long long ans=0;
        int mini1=INT_MAX;
        int mini2=INT_MAX;
        vector<vector<int>> nums(n,vector<int>());
        for(int i=0;i<n;i++){
            int s;
            cin>>s;
            vector<int> b(s);
            for(int j=0;j<s;j++) cin>>b[j];
            sort(b.begin(),b.end());
            ans+=b[1];
            mini1=min(mini1,b[0]);
            mini2=min(mini2,b[1]);
            nums.push_back(b);
        }
        cout<<ans-mini2+mini1<<"\n";
    }
    
    return 0;
}
