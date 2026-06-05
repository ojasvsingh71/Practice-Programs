#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int w,h;
        cin>>w>>h;

        long long ans=0;
        for(int i=0;i<2;i++){
            int len;
            cin>>len;
            vector<int> pts(len);
            for(int j=0;j<len;j++){
                cin>>pts[j];
            }
            ans=max(ans,(long long)(pts[len-1]-pts[0])*h);
            // cout<<ans<<"<";
        }
        for(int i=0;i<2;i++){
            int len;
            cin>>len;
            vector<int> pts(len);
            for(int j=0;j<len;j++){
                cin>>pts[j];
            }
            ans=max(ans,(long long)(pts[len-1]-pts[0])*w);
            // cout<<ans<<"<";
        }
        cout<<ans<<"\n";
    }
    
    return 0;
}
