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
        long long mini=LLONG_MAX;
        vector<long long> v(n),prefix_min(n,0);
        int bu=0;
        for(int i=0;i<n;i++){
            cin>>v[i];
            if(i>0){
                prefix_min[i]=min(v[i],prefix_min[i-1]);
            }else prefix_min[i]=v[i];
            // if(v[i]<mini){
            //     mini=v[i];
            //     bu=i;
            // }
        }
        vector<vector<long long>> nums(n,vector<long long>(m));
        priority_queue<long long,vector<long long>,greater<long long>> minpq;
        long long curr=0;
        vector<long long> hu;
        for(int i=0;i<n;i++){
            for(int j=0;j<m;j++){
                cin>>nums[i][j];
                if(i==0) {
                    minpq.push(nums[i][j]);
                    curr+=nums[i][j];
                }
                else (nums[i][j]>minpq.top()){
                    curr+=nums[i][j]-minpq.top();
                }
            }
            if(curr>=prefix_min[i]){
                ans=min(ans,)
            }

        }
        cout<<min(cnt,m)<<"\n";

    }
    
    return 0;
}
