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
        vector<int> cost(n);
        vector<pair<int,int>> pp;
        
        for(int i=0;i<n;i++) {
            cin>>cost[i];
            pp.push_back({cost[i],i+1});
        }
        
        sort(pp.rbegin(),pp.rend());

        vector<int> ans(n+1);
        ans[0]=0;
        int i=0;
        int j=1;
        while(i+1<n){
            ans[pp[i++].second]=j;
            ans[pp[i++].second]=-j;
            j++;
        }
        if(i<n){
            ans[pp[i].second]=j;
        }

        long long total=0;

        for(int i=0;i<n;i++){
            total+=(long long)2*abs(ans[0]-ans[i+1])*cost[i];
        }

        cout<<total<<"\n";
        for(int i:ans){
            cout<<i<<" ";
        }cout<<"\n";


    }
    
    return 0;
}
