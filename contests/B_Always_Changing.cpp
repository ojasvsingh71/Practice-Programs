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

        int z=0,o=0;
        for(char c:s){
            if(c=='0') z++;
            else o++;
        }
        if(abs(z-o)>2){
            cout<<-1<<"\n";
        }else{
            int cz=0,co=0;
            for(int i=1;i<n;i++){
                if(s[i]==s[i-1]){
                    int rs=i;
                    while(rs<n && s[rs]==s[i]) rs++;
                    if(s[i]=='0') cz+=rs-i;
                    else co+=rs-i;
                    i=rs-1;
                }
            }
            // cout<<cz<<" - "<<co<<"\t";
            int ans=2*min(co,cz);
            if(cz!=co) ans+=2*abs(co-cz)-1;

            cout<<ans<<"\n";

        }
    }
    
    return 0;
}
