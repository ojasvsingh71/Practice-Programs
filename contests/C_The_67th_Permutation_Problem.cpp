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

        for(int i=1;i<=n;i++){
            // printf("%d %d %d ",i,3*n-2*i+2,3*n-2*i+1);
            cout<<i<<" "<<3*n-2*i+2<<" "<<3*n-2*i+1<<" ";
        }cout<<"\n";
    }
    
    return 0;
}
