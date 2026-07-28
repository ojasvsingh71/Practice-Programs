#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n;
        cin>>n;
        vector<int> a(n),b(n);
        for(int i=0;i<n;i++) cin>>a[i];
        int onediff=0,zerodiff=0;
        for(int i=0;i<n;i++) {
            cin>>b[i];
            if(a[i] !=b[i]){
                if(a[i]) onediff++;
                else zerodiff++;
            }
        }
        if(zerodiff && !onediff) cout<<-1<<"\n";
        else if(!zerodiff && !onediff) cout<<0<<"\n";
        else if(onediff%2==0) cout<<2<<"\n";
        else cout<<1<<"\n"; 
    }
    
    return 0;
}
