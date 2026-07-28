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
        int bu=0;
        while(n>2){
            bu+=n/3;
            n-=2*(n/3);
        }cout<<bu<<"\n";
    }
    
    return 0;
}
