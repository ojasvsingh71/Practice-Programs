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

        int bu=0;
        // cout<<sqrt(n)<<" ";
        for(int i=2;i<=sqrt(n);i++){
            if(n%i==0){
                cout<<n/i<<" "<<n-n/i<<"\n";
                bu=1;
                break;
            }
        }
        if(!bu) cout<<1<<" "<<n-1<<"\n";
    }
    
    return 0;
}
