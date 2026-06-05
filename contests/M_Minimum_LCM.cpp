#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        long long n;
        cin>>n;
        if(n%2==0){
            cout<<n/2<<" "<<n/2<<"\n";
        }else{
            for(long long i=n/2;i>=1;i-=2){
                if((n-i)%i==0){
                    cout<<i<<" "<<n-i<<"\n";
                    break;
                }
            }
        }
    }
    
    return 0;
}
