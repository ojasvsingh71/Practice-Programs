#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n;
        long long k,b,s;
        cin>>n>>k>>b>>s;

        long long mini=k*b;
        long long  maxi=mini+n*(k-1);
        
        if(s>maxi || s<mini){
            cout<<-1<<"\n";
        }else{
            int i=0;
            long long bu=min(mini+k-1,s);
            while(i<n){
                cout<<bu<<" ";
                s-=bu;
                if(s>(k-1)){
                    bu=k-1;
                }else{
                    if(s>0) bu=s;
                    else bu=0;
                }
                i++;
            }
            cout<<"\n";
        }
    }
    
    return 0;
}
