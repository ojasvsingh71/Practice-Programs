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
        vector<int> nums(n);
        for(int i=0;i<n;i++)  cin>>nums[i];

        sort(nums.rbegin(),nums.rend());

        for(int i:nums) cout<<i<<" ";
        cout<<"\n";
    }
    
    return 0;
}
