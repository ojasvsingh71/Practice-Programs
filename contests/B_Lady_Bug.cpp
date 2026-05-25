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
        string a,b;
        cin>>a>>b;

        int odd_one=0,odd_zero=0,even_one=0,even_zero=0;

        for(int i=0;i<n;i++){
            if(a[i]=='1') {
                if(i%2==1)odd_one++;
                else even_one++;
            }
            if(b[i]=='0'){
                if(i%2==1) odd_zero++;
                else even_zero++;
            }
        }

        if(even_zero>=odd_one && odd_zero>=even_one) cout<<"YES\n";
        else cout<<"NO\n";
        
    }
    
    return 0;
}
