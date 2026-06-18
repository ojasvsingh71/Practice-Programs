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

        vector<vector<int>> nums(n,vector<int>(m));

        int sum=0,neg=0;
        int mini=INT_MAX;
        for(int i=0;i<n;i++){
            for(int j=0;j<m;j++){
                cin>>nums[i][j];
                sum+=abs(nums[i][j]);
                if(nums[i][j]<=0) neg++;
                mini=min(abs(nums[i][j]),mini);
            }
        }
        if(neg%2!=0){
            sum-=2*mini;
        }
        cout<<sum<<"\n";

    }
    
    return 0;
}
