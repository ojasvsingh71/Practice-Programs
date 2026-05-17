#include <bits/stdc++.h>
using namespace std;

bool good(long long x,long long y){
    long long res=stoll(to_string(x)+to_string(y));
    // cout<<res<<" ";
    return res%(x+y)==0;
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        long long x;
        cin>>x;
        for(int i=1;i<=1e9;i++){
            if(good(x,i)){
                cout<<i<<"\n";
                break;
            }
        }
    }
    
    return 0;
}
