#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;

    vector<int> nums(1e6,0);
        int k=1;
        vector<int> ans;
        ans.push_back(0);
        for(int i=0;i<=500;i++){
            while(nums[k]==1) k++;
            nums[k]=1;
            nums[k+ans.back()]=1;
            // cout<<k<<" ";
            ans.push_back(k);
        }

    while(t--){
        int n;
        cin>>n;

        for(int i=1;i<=n;i++) cout<<ans[i]<<" ";

        cout<<"\n";

    }
    
    return 0;
}
