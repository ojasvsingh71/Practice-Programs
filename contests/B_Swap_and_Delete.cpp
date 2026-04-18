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

        int z=0,o=0;
        for(char c:s){
            if(c=='0') z++;
            else o++;
        }
        if(o==z){
            cout<<0<<"\n";
        }else{
            
        }
    }
}