#include <bits/stdc++.h>
using namespace std;

long long dsum(long long n){
    int sum=0;
    while(n>0){
        sum+=n%10;
        n/=10;
    }return sum;
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n;
        cin>>n;
       
        int nd=dsum(n);
        int bu=0;
        for(int i=n;i<=n+100;i++){
            if(n==i-dsum(i)) {
                bu=1;
                break;
            }
        }
        if(bu) cout<<10<<"\n";
        else cout<<0<<"\n";
    }
    
    return 0;
}
