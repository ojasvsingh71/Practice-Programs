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
        for(int i=0;i<n;i++) cin>>b[i];

        int ans=0;
        int bu=0;
        for(int i=0;i<n;i++){
            if(a[i]>b[i]){
                int j=i+1;
                ans++;
                while(j<n && a[j]>b[i]){
                    j++;
                    ans++;k
                }
                if(j==n){
                    bu=1;
                    break;
                }
                int temp=a[j];
                for(int k=j;k>i;k--) a[k]=a[k-1];
                a[i]=temp;
            }
        }
        // for(int i:a) cout<<i<<" ";
        // cout<<"\n";
        if(bu) cout<<-1<<"\n";
        else cout<<ans<<"\n";
    }
    
    return 0;
}
