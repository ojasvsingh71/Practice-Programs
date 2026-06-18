#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n,x,y,z;
        cin>>n>>x>>y>>z;

        int fst=n/(x+y);
        if(n%(x+y)!=0) fst++;

        int sec=0;
        if(x*z>=n){
            sec=n/x;
            if(n%x!=0) sec++;
        }else{
            sec=z;
            n-=x*z;
            sec+=n/(x+10*y);
            if(n%(x+10*y)!=0) sec++;
        }
        // cout<<fst<<" "<<sec<<"\n";
        cout<<min(fst,sec)<<"\n";
        
    }
    
    return 0;
}
