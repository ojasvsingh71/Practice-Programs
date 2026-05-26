#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n,p;
        cin>>n>>p;
        
        vector<int> a(n),b(n);
        for(int i=0;i<n;i++) cin>>a[i];
        map<int,long long> freq;
        for(int i=0;i<n;i++){
            cin>>b[i];
            freq[b[i]]+=a[i];
        }
        long long ans=p;
        int sent=1;
        for(auto& i:freq){
            if(sent>=n) break;
            if(i.first>p){
                ans+=(long long)p*(n-sent);
                sent=n;
            }else{
                if(sent+i.second>n){
                    ans+=(long long)i.first*(n-sent);
                    sent=n;
                }else{
                    ans+=(long long)i.first*i.second;
                    sent+=i.second;
                }
            }
        }
        cout<<ans<<"\n";
    }
    
    return 0;
}
