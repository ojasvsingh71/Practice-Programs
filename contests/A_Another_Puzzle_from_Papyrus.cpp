#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n,c;
        cin>>n>>c;

        vector<int> a(n),b(n);
        // int maxia=0,maxib=0;
        int bu=0;
        for(int i=0;i<n;i++){
            cin>>a[i];
            // maxia=max(a[i],maxia);
        }
        for(int i=0;i<n;i++){
            cin>>b[i];
            if(b[i]>a[i]) bu=1;
            // maxib=max(b[i],maxib);
        }
        // if(maxib>maxia){
        //     cout<<-1<<"\n";
        //     continue;
        // }

        int ans=0;
        if(bu) {
            ans+=c;
            sort(a.begin(),a.end());
            sort(b.begin(),b.end());
        }
        bu=0;
        for(int i=0;i<n;i++){
            if(b[i]>a[i]){
                bu=1;
                break;
            }
            ans+=a[i]-b[i];
        }
        if(bu) cout<<-1<<"\n";
        else cout<<ans<<"\n";

    }
    
    return 0;
}
