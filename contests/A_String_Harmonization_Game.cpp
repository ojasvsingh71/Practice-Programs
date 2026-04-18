#include<bits/stdc++.h>
using namespace std;

int main(){
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int t;
    cin>>t;
    while(t--){
        int n;
        cin>>n;
        string s;
        cin>>s;

        int count=0;
        for(int i=1;i<n;i++){
            if((s[i]=='a' && s[i-1]=='b')|| (s[i]=='b' && s[i-1]=='a')){
                count++;
                i++;
            }
        }

        if(count%2==0) cout<<"Bob\n";
        else cout<<"Alice\n";
    }
}