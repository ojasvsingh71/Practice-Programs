#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        long long n,a,b;
        cin>>n>>a>>b;

        if(a*3<=b){
            cout<<n*a<<"\n";
        }else{
            long long allb=n/3*b;
            if(n%3!=0) allb+=b;
            long long both=n/3*b+n%3*a;
            cout<<min(allb,both)<<"\n";
        }
    }
    
    return 0;
}
