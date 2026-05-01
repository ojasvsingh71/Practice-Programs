#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int l=0,r=0;
        int n;
        cin>>n;
        
        vector<char> s(n);
        for(int i=0;i<n;i++){
            cin>>s[i];
            if(s[i]=='(') l++;
            else r++;
        }
        if(l==r) cout<<"YES\n";
        else cout<<"NO\n";

    }
    
    return 0;
}
