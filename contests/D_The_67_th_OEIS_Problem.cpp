#include <bits/stdc++.h>
using namespace std;

vector<int> sieve(int n){
    vector<int> prime(n+1,1);
    for(int i=2;i*i<=n;i++){
        if(prime[i]){
            for(int j=i*i;j<=n;j+=i){
                prime[j]=0;
            }
        }
    }
    vector<int> p;
    for(int i=2;i<=n;i++){
        if(prime[i]) p.push_back(i);
    }
    return p;
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    vector<int> prime=sieve(1e6+1);

    int t;
    cin>>t;
    while(t--){
        int n;
        cin>>n;
        for(int i=0;i<n;i++){
            long long bu=(long long) prime[i]*prime[i+1];
            cout<<bu<<" ";
        }cout<<"\n";
    }
    
    return 0;
}
