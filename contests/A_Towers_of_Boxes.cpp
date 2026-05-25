#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n,m,d;
        cin>>n>>m>>d;
        if(d<m){
            cout<<n<<"\n";
        }else{
            int div=(d/m);
            int res=n/(div+1);
            if(n%(div+1)>0) res++;
            cout<<res<<"\n";
        }
    }
    
    return 0;
}
