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
        if(s[0]==s[n-1]) cout<<1<<"\n";
        else {
            string fin;
            for(int i=0;i<n;i++){
                fin+=s[i];
                int rs=i+1;
                while(rs<n && s[rs]==s[i]) rs++;
                i=rs-1;
            }
            // cout<<fin<<"\n";
            if(fin.size()==2) cout<<2<<"\n";
            else cout<<1<<"\n";

        }
    }
    
    return 0;
}
