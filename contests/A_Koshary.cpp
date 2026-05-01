#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int x,y;
        cin>>x>>y;
        if(x%2==1 && y%2==1) cout<<"NO\n";
        else cout<<"YES\n";
    }
    
    return 0;
}
