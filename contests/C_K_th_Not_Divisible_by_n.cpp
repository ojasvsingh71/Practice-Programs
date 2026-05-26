#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        long long n,k;
        cin>>n>>k;

        if(k<n){
            cout<<k<<"\n";
        }else{
            long long temp=k;
            long long ans=0;
            while(temp/n>0){
                ans+=temp/n;
                long long rem=temp%n;
                temp=temp/n+rem;
            }
            cout<<k+ans<<"\n";
        }
    }
    
    return 0;
}
