#include <bits/stdc++.h>
using namespace std;

vector<int> seive(int n){
    vector<int> primes(n+1,1);
    primes[0]=primes[1]=0;
    for(int i=2;i*i<=n;i++){
        if(primes[i]){
            for(int j=i*i;j<=n;j+=i) primes[j]=0;
        }
    }
    vector<int> prime;
    for(int i=2;i<=n;i++) if(primes[i]) prime.push_back(i);

    return prime;
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    vector<int> prime=seive(1e5);

    int t;
    cin>>t;
    while(t--){
        int d;
        cin>>d;

        int fst=d+1;
        int i=0;
        while(prime[i]<fst) i++;
        int bu1=prime[i];
        fst=prime[i]+d; 
        while(prime[i]<fst) i++;
        cout<<prime[i]*bu1<<"\n";

    }
    
    return 0;
}
