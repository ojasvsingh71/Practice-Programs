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

        sort(nums.rbegin(),nums.rend());
        int x=nums[0],y=nums[1];
        int bu=0;
        for(int i=2;i<n;i++){
            if(nums[i]==x%y){
                x=y;
                y=nums[i];
            }else{
                bu=1;
                break;
            }
        }
        if(bu) cout<<-1<<"\n";
        else cout<<nums[0]<<" "<<nums[1]<<"\n";
    }
    
    return 0;
}
