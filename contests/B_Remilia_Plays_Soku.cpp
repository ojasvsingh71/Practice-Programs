#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        long long n,x,y,k;
        cin>>n>>x>>y>>k;
        if(n==2 || n==3){
            cout<<1<<"\n";
        }else{
            long long ans=k;
            long long dur=max(x,y);
            long long pass=min(x,y);
            ans+=min(dur-pass,n-dur+pass);

            cout<<ans<<"\n";
        }
    }
    
    return 0;
}
