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
        vector<int> nums(n+1);
        for(int i=1;i<=n;i++) cin>>nums[i];
       
        
        vector<int> minidiv(n+1,-1);
        for(int i=1;i<=n;i++){
            if(minidiv[i]!=-1) continue;
            for(int j=i;j<=n;j*=2){
                minidiv[j]=i;
            }
        }

        // for(int i=1;i<=n;i++) cout<<minidiv[i]<<" ";

        // cout<<"\n";

        int bu=0;
        for(int i=1;i<=n;i++){
            if(minidiv[i]!=minidiv[nums[i]]){
                bu=1;
                break;
            }
        }

        if(bu) cout<<"NO\n";
        else cout<<"YES\n";
    
    }
    
    return 0;
}
