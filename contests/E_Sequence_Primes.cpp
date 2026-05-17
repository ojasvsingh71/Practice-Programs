#include <bits/stdc++.h>
using namespace std;

vector<bool> prime(1e6+1,true);
vector<long long> primes;

void sieve(){
    for(int i=2;i*i<=1e6;i++){
        if(prime[i]){
            for(int j=i*i;j<=1e6;j+=i){
                prime[j]=false;
            }
        }
    }
    for(int i=2;i<=1e6;i++){
        if(prime[i]) primes.push_back(i);
    }
}

bool isPrime(long long n){
    if(n<2) return false;

    for(long long i:primes){
        if(i*i>n) break;
        if(n%i==0) return false;
    }
    return true;
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    sieve();
    prime[0]=false;
    prime[1]=false;
    int t;
    cin>>t;
    while(t--){
        long long c,x;
        cin>>x>>c;

        bool found=false;

        for(long long k=0;k<=1e6;k++){
            if(isPrime(k*x+c)){
                cout<<x*k+c<<"\n";
                found=true;
                break;
            }
        }
        if(!found) cout<<-1<<"\n";
    }

    
    return 0;
}
