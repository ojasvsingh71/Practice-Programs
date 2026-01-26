#include<bits/stdc++.h>
using namespace std;

int main(){
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int t;
    cin>>t;
    while(t--){
        int n;
        cin>>n;
        vector<int> a(n);
        vector<int> b(n);
        for(int i=0;i<n;i++) cin>>a[i];
        for(int i=0;i<n;i++) cin>>b[i];
        sort(a.begin(),a.end());
        vector<long long> prefix(n,0);
        prefix[0]=b[0];
        for(int i=1;i<n;i++){
            prefix[i]=prefix[i-1]+b[i];
        }
        long long maxi=0;
        int diff=a[0],j=n-1;
        for(int i=0;i<n;i++){
            diff=a[i];
            int swords=n-i;
            while(swords<prefix[j]) j--;
            maxi=max(maxi,(long long)diff*(j+1));
        }
        cout<<maxi<<"\n";
    }
}