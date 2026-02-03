#include<bits/stdc++.h>
using namespace std;

int main(){
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int t;
    cin>>t;
    while(t--){
        long long n;
        cin>>n;
        string s;
        cin>>s;
        long long st=0;
        if(n<3){
            if(n==1 && s[0]=='0') st++;
            if(n==2 && s=="00") st++; 
        }
        for(char c:s) if(c=='1') st++;
        for(int i=1;i<n-1;i++){
            if(s[i-1]=='0' && s[i]=='0' && s[i+1]=='0') {
                st++;
                s[i]='1';
            }
        }
        if(n>=3){
            if(s[0]=='0' && s[1]=='0' && s[2]=='1'){
                s[0]='1';
                st++;
            }
            if(s[n-1]=='0' && s[n-2]=='0' && s[n-3]=='1'){
                s[n-1]='1';
                st++;
            }
        }
        cout<<st<<"\n";
    }
}