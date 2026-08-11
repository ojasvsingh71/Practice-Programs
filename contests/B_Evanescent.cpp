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

        string s;
        cin>>s;

        int hu=0;
        int cnt=0;
        string comp;
        for(int i=1;i<n-1;i++){
            if(s[i-1]==s[i+1] && s[i]!=s[i-1]){
                hu=1;
                break;
            }
        }
        int bu=0;
        for(int i=0;i<n;i++){
            cnt++;
            comp+=s[i];
            int rs=i+1;
            while(rs<n && s[rs]==s[i]) rs++;
            i=rs-1; 
            if(i>0 && i<n-1 && s[i]!=s[i-1] && s[i]!=s[i+1]) bu=1;
        }
        n=comp.size();
        if(hu) cnt--;
        if(n>2 && bu)cnt--;
        cout<<cnt<<"\n";
    }
    
    return 0;
}
