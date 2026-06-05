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
        vector<int> a_conti(n,1),b_conti(n,1);

        vector<int> a_fin(2*n+1,0),b_fin(2*n+1,0);

        for(int i=0;i<n;i++){
            cin>>a[i];
            if(a_fin[a[i]]==0){
                a_fin[a[i]]=1;
            }
            if(i>0){
                if(a[i]==a[i-1]){
                    a_conti[i]+=a_conti[i-1];
                }
                a_fin[a[i]]=max(a_fin[a[i]],a_conti[i]);
            }
        }
        for(int i=0;i<n;i++){
            cin>>b[i];
            if(b_fin[b[i]]==0){
                b_fin[b[i]]=1;
            }
            if(i>0){
                if(b[i]==b[i-1]){
                    b_conti[i]+=b_conti[i-1];
                }
                b_fin[b[i]]=max(b_fin[b[i]],b_conti[i]);
            }
        }
        int ans=0;
        for(int i=1;i<=2*n;i++){
            ans=max(ans,a_fin[i]+b_fin[i]);
        }
        cout<<ans<<"\n";


    }
    
    return 0;
}
