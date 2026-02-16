#include<bits/stdc++.h>
using namespace std;

int main(){
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int t;
    cin>>t;
    while(t--){
        int n,m,k;
        cin>>n>>m>>k;
        string s,p;
        cin>>s>>p;
        
        int dist=0,j=0;
        for(int i=0;i<n && j<m;i++){
            if(s[i]==p[j]) j++;
        }

        if(j!=m){
            cout<<-1<<"\n";
            continue;
        }

        cout<<(dist+n-m+k-1)/k<<"\n";

    }
}