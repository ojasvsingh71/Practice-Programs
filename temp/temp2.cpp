#include<bits/stdc++.h>
using namespace std;
 
int main()
{
    ios::sync_with_stdio(false);
    cin.tie(nullptr);
 
 
    int t;
    cin>>t;
    while(t--){
        int n,x,k;
        cin>>n>>x>>k;
        // cout<<x%k<<"\n";
        if(x+(k-x%k)<=n) cout<<min(x%k,k-x%k);
        else cout<<x%k;
        cout<<"\n";
    }
 
 
}