#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n;
        long long k;
        cin>>n>>k;
        vector<int> nums(n);
        for(int i=0;i<n;i++) cin>>nums[i];

        map<int,vector<int>> dis;
        for(int i=0;i<n;i++){
            dis[nums[i]%k].push_back(i+1);
        }

        for(int i:dis[0]) cout<<i<<" ";
        for(auto i=dis.rbegin();i!=dis.rend();i++){
            if(i->first==0) continue;
            for(int j:i->second){
                cout<<j<<" ";
            }
        }
        cout<<"\n";
    }
    
    return 0;
}
