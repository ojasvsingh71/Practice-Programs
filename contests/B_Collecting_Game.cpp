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
        for(int i=0;i<n;i++){
            cin>>nums[i];
        }
        vector<long long> prefix(n);
        vector<int> temp(nums.begin(),nums.end());
        sort(temp.begin(),temp.end());
        for(int i=0;i<n;i++){
            if(i==0) prefix[i]=temp[i];
            else prefix[i]=temp[i]+prefix[i-1];
        }
        unordered_map<int,int> ans;
        for(int i=0;i<n;i++){
            
            int found=i;
            int j=i;
            while(j<n){
                int idx=lower_bound(temp.begin(),temp.end(),prefix[j]+1)-temp.begin();
                idx--;
                if(idx==j) break;
                j=idx;
            }
            ans[temp[i]]=j;
        }
        for(int i:nums){
            cout<<ans[i]<<" ";
        }
        cout<<"\n";
    }
    
    return 0;
}
