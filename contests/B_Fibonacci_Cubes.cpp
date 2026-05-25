#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n,m;
        cin>>n>>m;

        vector<int> fib(n);
        fib[0]=1;
        fib[1]=2;
        for(int i=2;i<n;i++){
            fib[i]=fib[i-1]+fib[i-2];
        }
        string ans;
        int last=fib[n-1]+fib[n-2],seclast=fib[n-1];
        for(int i=0;i<m;i++){
            int w,l,h;
            cin>>w>>l>>h;

            int thrd=max({w,l,h});
            int fst=min({w,l,h});
            int sec=w+l+h-fst-thrd;

            if(thrd>=last && sec>=seclast && fst>=seclast) ans+='1';
            else ans+='0';
        }
        cout<<ans<<"\n";
    }
    
    return 0;
}
