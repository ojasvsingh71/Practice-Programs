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

        int bu=0;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            if(i>0){
                if(nums[i]<nums[i-1]) bu=1;
            }
        }
        if(bu) cout<<1<<"\n";
        else cout<<n<<"\n";
    }
    
    return 0;
}
