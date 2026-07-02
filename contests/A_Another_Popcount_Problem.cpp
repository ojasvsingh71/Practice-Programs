#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n,k;
        cin>>n>>k;

        if(n<=k){
            cout<<n<<"\n";
            continue;
        }

        int limit=n/k;
        int bu=1,len=0;
        while(bu<=limit){
            bu=(bu<<1);
            bu++;
            len++;
        }
        bu=(bu>>1);
        
        int diff=(n-(k*bu));

        int temp=bu<<1;
        temp++;
        int diff2=temp-bu;
        
        int len2=(temp<=n) ? diff/diff2 : 0;
        cout<<k*len+len2<<"\n";
        
    }
    
    return 0;
}
