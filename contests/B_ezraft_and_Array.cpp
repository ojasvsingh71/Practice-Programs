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
        if(n==1) {
            cout<<1<<"\n";
            continue;
        }
        
        if(n==2) {
            cout<<-1<<"\n";
            continue;
        }
        cout<<1<<" "<<2<<" ";
        long long curr=3;
        for(int i=3;i<=n;i++){
            cout<<curr<<" ";
            curr*=2;
        }
        cout<<"\n";
    }
    
    return 0;
}
