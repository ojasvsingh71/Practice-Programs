#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n,k;
        cin>>n>>k;

        int one=n/2,zero=n/2;
        if(n%2==1) one++;

        int p=one-1+zero-1;
        if(k>p){
            cout<<-1<<"\n";
            continue;
        }
        int onek=k/2,zerok=k/2;
        if(k%2==1) onek++;

        string ans="";
        ans+="1";
        one--;
        for(int i=0;i<onek;i++) {
            ans+="1";
            // cout<<1;
            one--;
        }
        ans+="0";
        // cout<<0;
        zero--;
        for(int i=0;i<zerok;i++) {
            ans+="0";
            // cout<<0;
            zero--;
        }
        while(one && zero){
            ans+="10";
            one--;
            zero--;
        }
        while(one--) ans+="1";
        if(zero){
            ans="0"+ans;
            zero--;
        }
        while(zero--) ans+="0";
        cout<<ans<<"\n";
    }
    
    return 0;
}
