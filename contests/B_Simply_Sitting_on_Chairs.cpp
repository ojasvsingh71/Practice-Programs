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
        int cnt=0;
        for(int i=0;i<n;i++){
            if(nums[i]<=i+1) cnt++;
        }
        cout<<cnt<<"\n";
    }
    
    return 0;
}
