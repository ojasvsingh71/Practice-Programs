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
        int bu=0;
        int blocks=0;
        unordered_map<char,int> freq;
        freq[s[0]]++;
        for(int i=1;i<n;i++){
            if(s[i]!=s[i-1]) blocks++;
            if(freq[s[i]]) bu=1;
            freq[s[i]]++; 
        }
        if(s[0]!=s.back() && bu) cout<<blocks+2<<"\n";
        else cout<<blocks+1<<"\n";
    }
    
    return 0;
}
