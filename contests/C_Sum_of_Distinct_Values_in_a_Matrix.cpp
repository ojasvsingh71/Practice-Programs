#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n,m,x,y;
        cin>>n>>m>>x>>y;
        vector<long long> a(x),b(y);
        for(int i=0;i<x;i++) cin>>a[i];
        for(int i=0;i<y;i++) cin>>b[i];

        sort(a.rbegin(),a.rend());
        sort(b.rbegin(),b.rend());
        long long fst=0,sec=0;
        long long fst2=0,sec2=0;
        for(int i=0;i<min(x,n);i++){
            if(i==n-1) fst+=a[i];
            else {
                fst+=a[i];
                fst2+=a[i];
            }
        }
        for(int i=0;i<min(y,m);i++){
            if(i==m-1) sec2+=b[i];
            else {
                sec2+=b[i];
                sec+=b[i];
            }
        }
        // cout<<fst<<"\t"<<sec<<"\n";
        cout<<max(fst+sec,fst2+sec2)<<"\n";
    }
    
    return 0;
}
