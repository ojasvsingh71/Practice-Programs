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

        vector<int> ao,bo,ae,be;
        for(int i=0;i<n;i++){
            if(a[i]=='1'){
                if(i%2==0){
                    ae.push_back(i);
                }else ao.push_back(i);
            }
        }
        for(int i=0;i<n;i++){
            if(b[i]=='1'){
                if(i%2==0){
                    be.push_back(i);
                }else bo.push_back(i);
            }
        }
        if(ao.size()!=bo.size() || ae.size()!=be.size()) cout<<-1<<"\n";
        else{
            int ans=0;
            int m=ao.size();
            for(int i=0;i<m;i++){
                ans+=abs(ao[i]-bo[i])/2;
            }
            m=ae.size();
            for(int i=0;i<m;i++){
                ans+=abs(ae[i]-be[i])/2;
            }
            cout<<ans<<"\n";
        }
    }
    
    return 0;
}
