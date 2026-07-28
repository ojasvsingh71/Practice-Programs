#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n,k,m;
        cin>>n>>k>>m;

        if(k>m) {
            cout<<"NO\n";
            continue;
        }
        cout<<"YES\n";
        for(int i=0;i<k-1;i++) cout<<1<<" ";
        cout<<m-k+1<<" ";
        for(int i=k;i<n;i++) cout<<1<<" ";
        cout<<"\n";

    }
    
    return 0;
}
