#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        string s;
        cin>>s;
        int ans=0;

        int three=0,one=0;
        for(char c:s){
            if(c=='4') ans++;
            else if(c=='2'){
                if(three>0){
                    ans++;
                    three--;
                }else if(one>0){
                    ans++;
                    one--;
                }
            }else if(c=='3') three++;
            else one++;
        }

        cout<<ans<<"\n";
    }
    
    return 0;
}
