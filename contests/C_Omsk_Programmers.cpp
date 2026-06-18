#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);


    int t;
    cin>>t;
    while(t--){
        int a,b,x;
        cin>>a>>b>>x;

        vector<int> fst,sec;
        fst.push_back(a);
        sec.push_back(b);

        while(a>0){
            fst.push_back(a/x);
            a/=x;
        }
        while(b>0){
            sec.push_back(b/x);
            b/=x;
        }

        int m=fst.size();
        int k=sec.size();

        int ans=INT_MAX;
        for(int i=0;i<m;i++){
            for(int j=0;j<k;j++){
                ans=min(ans,abs(fst[i]-sec[j])+i+j);
            }
        }
        

        cout<<ans<<"\n";
    }
    
    return 0;
}
