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

        for(int i=0;i+k<n;i++){
            if(s[i]=='1'){
                s[i]='0';
                if(s[i+k]=='1') s[i+k]='0';
                else s[i+k]='1';
            }
        }
        int bu=0;
        for(char c:s){
            if(c=='1'){
                bu=1;
                break;
            }
        }
        if(bu) cout<<"NO\n";
        else cout<<"YES\n";
    }
    
    return 0;
}
