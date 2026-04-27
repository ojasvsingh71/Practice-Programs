#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        long long x,y;
        cin>>x>>y;

        if(y-x>x && (y-x)%x==0 && (y-x)%y!=0) cout<<"YES\n";
        else cout<<"NO\n";
    }
    
    return 0;
}
