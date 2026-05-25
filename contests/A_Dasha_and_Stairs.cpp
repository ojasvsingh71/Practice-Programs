#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int l,r;
    cin>>l>>r;

    if(abs(l-r)>1 || (l==0 && r==0 )){
        cout<<"NO\n";
    }else cout<<"YES\n";
    
    return 0;
}
