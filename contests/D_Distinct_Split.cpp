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
        unordered_map<char,int> freqb;
        for(char c:s){
            freqb[c]++;
        }
        unordered_map<char,int> freqa;
        int ans=freqb.size();
        for(char c:s){
            freqa[c]++;
            freqb[c]--;
            if(freqb[c]==0){
                freqb.erase(c);
            }
            ans=max(ans,(int)freqa.size()+(int)freqb.size());
        }
        cout<<ans<<"\n";
    }
    
    return 0;
}
