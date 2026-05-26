#include<bits/stdc++.h>
using namespace std;

int main(){
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int t;
    cin>>t;
    while(t--){
        string s;
        cin>>s;
        int n=s.size();

        int zero=0,one=0;
        for(char c:s){
            if(c=='0') zero++;
            else one++;
        }
        int i=0;
        while(i<n && ((s[i]=='0' && one>0) || (s[i]=='1' && zero>0))){
            if(s[i]=='0') one--;
            else zero--;
            i++;
        }
        cout<<n-i<<"\n";
    }
}