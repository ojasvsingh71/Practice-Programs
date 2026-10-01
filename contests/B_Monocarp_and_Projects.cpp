#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        long long x,y;
        long long k;
        cin>>x>>y>>k;

        long long ans=0;
        while(k>0){
            k--;
            long long bu=y%x;
            // cout<<bu<<" - ";
            if(2*x==y) break;
            if(2*x>y) {
                k++;
                break;
            }
            ans+=bu;
            x++;
            y++;
            // k--;
            // cout<<k<<" ";
        }
        x++;
        y++;
        if(k>0) {
            ans+=(y-x)*k;
            // cout<<(y%x)<<" ";
            // x++,y++;
            // cout<<(y%x)<<" ";
        }
        cout<<ans<<"\n";
    }
    
    return 0;
}
