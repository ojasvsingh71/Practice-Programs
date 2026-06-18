#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        long long x,y,k;
        cin>>x>>y>>k;

        // long long req=(k-1+y*k);
        // long long st=1;
        // long long ans=0;
        // while(st<req){
        //     st+=x-1;
        //     ans++;
        // }
        long long ans=(k-1+y*k)/(x-1);
        if((k-1+y*k)%(x-1)!=0) ans++;
        cout<<ans+k<<"\n";
    }
    
    return 0;
}
