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
        string s;
        cin>>s;
        if(n<2*k) {
            cout<<-1<<"\n";
            continue;
        }
        int ans=0;
        int l=0,r=0;
        for(int i=0;i<n;i++){
            if(s[i]=='L' && r<k){
                s[i]='R';
                ans++;
            }
            if(s[i]=='L') l++;
            else r++;
        }
        l=0,r=0;
        for(int i=n-1;i>=0;i--){
            if(s[i]=='R'&& l<k){
                s[i]='L';
                ans++;
            }
            if(s[i]=='L') l++;
            else r++;
        }
        cout<<ans<<"\n";
        
    }
    
    return 0;
}
