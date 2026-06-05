#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int a,b;
        cin>>a>>b;

        int bu=1;
        int ans=0;
        int mini=min(a,b);
        int maxi=max(a,b);

        while(bu<=mini || bu<=maxi){
            if(mini>=bu){
                mini-=bu;
                ans++;
                bu=bu<<1;
            }else break;
            
            if(maxi>=bu) {
                maxi-=bu;
                ans++;
                bu=bu<<1;
            }else break;
        }
        maxi=max(a,b);
        mini=min(a,b);
        bu=1;
        int ans2=0;
        while(bu<=mini || bu<=maxi){
            if(maxi>=bu){
                maxi-=bu;
                ans2++;
                bu=bu<<1;
            }else break;
            
            if(mini>=bu) {
                mini-=bu;
                ans2++;
                bu=bu<<1;
            }else break;
        }
        cout<<max(ans2,ans)<<"\n";
    }
    
    return 0;
}
