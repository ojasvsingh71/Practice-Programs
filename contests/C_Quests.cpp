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
        vector<int> a(n),b(n);
        for(int i=0;i<n;i++) cin>>a[i];
        for(int i=0;i<n;i++) cin>>b[i];
        vector<int> bu(n);
        int maxi=0;
        int curr=0;
        int ans=0;
        for(int i=0;i<min(k,n);i++){
            maxi=max(maxi,b[i]);
            curr+=a[i];
            bu[i]=curr+(maxi*(k-i-1));
            ans=max(ans,bu[i]);
        }
        // for(int i:bu) cout<<i<<" ";
        // cout<<"\t";
        cout<<ans<<"\n";
    }
    
    return 0;
}
