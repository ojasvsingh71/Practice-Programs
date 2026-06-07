#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){

        int a,b;
        cin>>a>>b;
        
        int x=0,ans=a;
        int rem=(a-1)%4;

        if(rem==0) x=a-1;
        else if(rem==1) x=1;
        else if(rem==2) x=a;

        if(x!=b){
            ans++;
            if((x^b)==a) ans++;
        }

        cout<<ans<<"\n";
    }
    
    return 0;
}
