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
        unordered_map<char,int> freq;
        string s;
        cin>>s;
        for(int i=0;i<k;i++){
            freq[s[i]]++;
        }
        int ans=freq['W'];
        for(int i=k;i<n;i++){
            freq[s[i-k]]--;
            freq[s[i]]++;
            ans=min(ans,freq['W']);
        }
        cout<<ans<<"\n";
    }
    
    return 0;
}
