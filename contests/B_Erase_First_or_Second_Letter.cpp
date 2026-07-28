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
        unordered_set<char> seen;
        int ans=0;
        int cnt=0;
        for(char c:s){
            if(!seen.count(c)){
                seen.insert(c);
                cnt++;
            }ans+=cnt;
        }
        cout<<ans<<"\n";
    }
    
    return 0;
}
