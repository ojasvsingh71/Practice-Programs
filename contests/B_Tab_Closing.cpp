#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        long long a,b,n;
        cin>>a>>b>>n;
        long long count=0;
        while(n*b>a){
            n--;
            count++;
        }
        cout<<count+1<<"\n";

    }
    
    return 0;
}
