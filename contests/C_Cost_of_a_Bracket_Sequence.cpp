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

        string s;
        cin>>s;

        vector<int> ans(n,0);
        
        int ls=0,rs=n-1;
        while(k>0 && ls<rs){
            k
            while(ls<n && s[ls]==')') ls++;
            if(ls<n && ans[ls]==0){
                ans[ls++]=1;
                k--;
            }

            if(k==0) break;
            while(0<=rs && s[rs]=='(') rs--;
            if(rs>=0 && ans[rs]==0){
                ans[rs--]=1;
                k--;
            }
        }
        // cout<<k<<"-";
        int i=0;
        while(i<n && k>0){
            if(ans[i]==0){
                ans[i]=1;
                k--;
            }i++;
        }
        for(int i:ans){
            cout<<i;
        }
        cout<<"\n";
    }
    
    return 0;
}
