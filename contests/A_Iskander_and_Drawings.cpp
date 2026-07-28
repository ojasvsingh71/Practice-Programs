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
        string s;
        cin>>s;
        int ans=0;
        for(int i=0;i<n;i++){
            if(s[i]=='#'){
                int rs=i;
                while(rs<n && s[rs]!='*') rs++;
                ans=max(ans,rs-i);
                i=rs-1;
            }
        }
        if(ans%2!=0) ans++;
        cout<<ans/2<<"\n";
    }
    
    return 0;
}
