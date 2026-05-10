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
        string s=to_string(n);
        int len=s.size();

        int ans=(len-1)*9;
        ans+=n/pow(10,len-1);
        cout<<ans<<"\n";
    }
    
    return 0;
}
