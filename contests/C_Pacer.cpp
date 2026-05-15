#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        long long n,m;
        cin>>n>>m;
        int side=0;
        long long ans=m;
        for(int i=0;i<n;i++){
            long long min,s;
            cin>>min>>s;
            if(min%2==0){
                if(s!=side){
                    side=1-side;
                    ans--;
                }
            }else{
                if(s!=1-side){
                    side=1-side;
                    ans--;
                }
            }
            // cout<<min<<" -- "<<ans<<"\n";
        }
        cout<<ans<<"\n";

    }
    
    return 0;
}
