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
        int bu=0;
        int hu=0;
        int q=0;
        for(int i=1;i<n-1;i++){
            if(s[i-1]!='?' && s[i-1]==s[i+1]){
                bu=1;
                break;
            }
        }
        // for(int i=1;i<n;i++){
        //     if(s)
        // }
        if(bu){
            cout<<0<<"\n";
        }else{
            for(int i=1;i<n;i++){
                if(s[i-1]!='?' && s[i]!='?' )  {
                    hu=1;
                    break;
                }
                if(s[i]=='?') q++;
            }
            if(s[0]=='?') q++;
            if(hu || q==0) cout<<1<<"\n";
            else if(q==n) cout<<4<<"\n";
            else cout<<2<<"\n";
        }
    }
    
    return 0;
}
