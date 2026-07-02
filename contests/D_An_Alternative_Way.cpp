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

        vector<int> a(n),b(n);

        for(int i=0;i<n;i++) cin>>a[i];
        long long bu=0;
        for(int i=0;i<n;i++){
            cin>>b[i];
        }
        
        for(int i=n-1;i>=0;i--){
            if(a[i]>b[i]){
                bu+=a[i]-b[i];
            }
            else{
                bu-=(b[i]-a[i]);
                bu=max((long long)0,bu);
            }
        }
        if(bu>0) cout<<"NO\n";
        else cout<<"YES\n";
    }   

    return 0;
}
