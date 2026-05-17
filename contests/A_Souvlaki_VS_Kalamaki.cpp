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
        sort(nums.begin(),nums.end());
        int bu=0;
        for(int i=1;i<n;i++){
            if(i%2==0 && nums[i]!=nums[i-1]){
                bu=1;
                break;
            }
        }
        if(bu) cout<<"NO\n";
        else cout<<"YES\n";
    }
    
    return 0;
}
