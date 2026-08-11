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

        int ao=0,bo=0,ae=0,be=0;
        for(int i=0;i<n;i++){
            if(a[i]=='1'){
                if(i%2==0) ae++;
                else ao++;
            } 
        }
        for(int i=0;i<n;i++){
            if(b[i]=='1'){
                if(i%2==0) be++;
                else bo++;
            } 
        }
        if(ao==bo && ae==be) cout<<"YES\n";
        else cout<<"NO\n";
    }
    
    return 0;
}
