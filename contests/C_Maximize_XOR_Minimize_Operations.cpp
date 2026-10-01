#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        double x,y;
        cin>>x>>y;

        cout<<x+y<<" "<<min(x,y)<<"\n";
    }
    
    return 0;
}
