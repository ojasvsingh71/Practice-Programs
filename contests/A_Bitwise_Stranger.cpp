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

        long long a=-1+n,b=-1-n,c=1+n,d=1-n;
        if((n&a)==0) cout<<a<<"\n";
        else if((n&b)==0) cout<<b<<"\n";
        else if((n&c)==0) cout<<c<<"\n";
        else if((n&d)==0) cout<<d<<"\n";
        else cout<<-1<<"\n";
    }
}