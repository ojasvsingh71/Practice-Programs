#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n;
        char t;
        cin>>n>>t;
        string s;
        cin>>s;
        if(t=='g') {
            cout<<0<<"\n";
            continue;
        }
        int finish=0;
        int ans=0;
        for(int i=0;i<n;i++){
            if(s[i]==t){
                int j=i;
                while(s[j]!='g'){
                    if(j==n-1) finish=1;
                    j=(j+1)%n;
                }
                if(j>i) ans=max(ans,j-i);
                else{
                    ans=max(ans,n-i+j);
                }
                i=j;
            }
            if(finish) break;
        }
        cout<<ans<<"\n";
    }
    
    return 0;
}
