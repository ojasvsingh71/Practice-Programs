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
        for(int i=0;i<n;i++) cin>>nums[i];

        if(nums[0]==-1 && nums[n-1]==-1){
            nums[0]=nums[n-1]=0;
        }else if(nums[0]==-1) nums[0]=nums[n-1];
        else if(nums[n-1]==-1) nums[n-1]=nums[0];

        cout<<abs(nums[0]-nums[n-1])<<"\n";
        for(int i=0;i<n;i++){
            if(nums[i]==-1) nums[i]=0;
            cout<<nums[i]<<" ";
        }
        cout<<"\n";

    }
    
    return 0;
}
