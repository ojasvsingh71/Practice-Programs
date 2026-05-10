#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n,m;
        long long h;
        cin>>n>>m>>h;
        vector<int> a(n);
        vector<int> version(n,0);
        vector<long long> change(n,0);
        
        for(int i=0;i<n;i++) cin>>a[i];
        
        int currversion=1;
        for(int i=0;i<m;i++){
            int j;
            long long c;
            cin>>j>>c;
            j--;

            if(version[j]!=currversion){
                version[j]=currversion;
                change[j]=0;
            }
            change[j]+=c;

            if(a[j]+change[j]>h){
                currversion++;
            }

        }

        for(int i=0;i<n;i++){
            if(version[i]==currversion){
                cout<<a[i]+change[i]<<" ";
            }else cout<<a[i]<<" ";
        }

        cout<<"\n";
    }
    
    return 0;
}
