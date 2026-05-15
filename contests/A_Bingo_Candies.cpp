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
        int bu=0;
        vector<vector<int>> nums(n,vector<int>(n));
        unordered_map<int,int> freq;
        long long limit=n*n-n;
        for(int i=0;i<n;i++){
            for(int j=0;j<n;j++){
                cin>>nums[i][j];
                if(freq[nums[i][j]]==limit){
                    bu=1;
                }
                freq[nums[i][j]]++;
            }
        }
        if(bu) cout<<"NO\n";
        else cout<<"YES\n";
    }
    
    return 0;
}
