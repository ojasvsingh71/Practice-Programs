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
        vector<int> b(k+1);
        vector<int> a(n+1);
        int cnt=0;
        for(int i=1;i<=k;i++) cin>>b[i];
        unordered_map<int,vector<int>> levels;
        for(int i=1;i<=n;i++) {
            cin>>a[i];
            cnt+=k+1-min(k+1,a[i]);
            levels[a[i]].push_back(i);
        }

        if(cnt>1000){
            cout<<-1<<"\n";
            continue;
        }
        cout<<cnt<<"\n";
        if(cnt==0) {
            cout<<"\n";
            continue;
        }

        for(int i=k;i>0;i--){
            if(!levels[i].empty()){
                
                for(int kk:levels[i]) {
                    for(int j=i;j<=k;j++){
                        cout<<kk<<" ";
                    }
                }
                
            }
        }
        cout<<"\n";

    }
    
    return 0;
}
