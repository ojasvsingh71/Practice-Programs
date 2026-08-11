#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        long long x,y,z;
        cin>>x>>y>>z;
        
            vector<int> nums={x,y,z};
            sort(nums.begin(),nums.end());
            cout<<min(nums[0]+nums[1],nums[2])-nums[0]<<"\n";
        
    }
    
    return 0;
}
