#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n;
        long long x,y;
        cin>>n>>x>>y;

        string s;
        cin>>s;
        int four=0,eight=0;
        for(char c:s){
            if(c=='4') four++;
            else eight++;
        }

        x=abs(x);
        y=abs(y);
        long long len=four+eight;
        long long maxi=max(x,y);
        if(maxi>len) cout<<"NO\n";
        else{
            if(maxi<=eight+four/2) cout<<"YES\n";
            else{
                long long mini=min(x,y);
                if(mini<=maxi-(four-(2*(len-maxi)))) cout<<"YES\n";
                else cout<<"NO\n";
            }
        }

    }
    
    return 0;
}
