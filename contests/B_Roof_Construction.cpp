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

        int num=1;
        while((num<<1)<n) num=num<<1;

        int back=num-1;
        while(back>=0) cout<<back--<<" ";

        while(num<n) cout<<num++<<" ";
        cout<<"\n";
        
    }
    
    return 0;
}
