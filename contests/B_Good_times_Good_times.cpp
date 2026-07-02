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
        int d=1;
        int k=s.size();
        while(k--) d*=10;
        cout<<d+1<<"\n";
    }
    
    return 0;
}
