#include<bits/stdc++.h>
using namespace std;

int main(){
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int t;
    cin>>t;
    while(t--){
        long long x,y;
        cin>>x>>y;
        if(((x+4*y)>=0) && ((x-2*y)%3==0) && (x-2*y)>=0) cout<<"YES\n";
        else cout<<"NO\n";
    }
}