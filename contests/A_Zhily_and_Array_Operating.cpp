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
        int bu=-1;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            if(nums[i]>=0) bu=i;
        }
        for(int i=bu;i>=0;i--){
            if(i<n-1) nums[i]=nums[i]+nums[]
        }
    }  
    
    return 0;
}
