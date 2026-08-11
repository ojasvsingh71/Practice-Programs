#include <bits/stdc++.h>
using namespace std;

vector<bool> prime(1e6+1,true);
void sieve(){
    for(int i=2;i*i<=1e6;i++){
        if(prime[i]){
            for(int j=i*i;j<=1e6;j+=i){
                prime[j]=false;
            }
        }
    }
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    sieve();
    while(t--){
        int n;
        cin>>n;

        if(prime[n+1]) cout<<"YES\n";
        else cout<<"NO\n";

    }
    
    return 0;
}
