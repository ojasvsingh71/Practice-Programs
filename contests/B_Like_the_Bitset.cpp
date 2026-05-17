#include <bits/stdc++.h>
using namespace std;


int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n,k;
        cin>>n>>k;
        string s;
        cin>>s;

        int bu=0;
        int ones=0;
        
        for(int ls=0;ls<n;ls++){
            int rs=ls+1;
        }

        if(bu && ones>0) {
            cout<<"NO\n";
            continue;
        }else cout<<"YES\n";
        vector<int> ans(n);
        int j=1;
        for(int i=0;i<n;i++){
            if(s[i]=='1'){
                ans[i]=j++;
            }
        }
        for(int i=0;i<n;i++){
            if(s[i]!='1') ans[i]=j++;
        }
        for(int i=0;i<n;i++) cout<<ans[i]<<" ";
        cout<<"\n";
    }
    
    return 0;
}
