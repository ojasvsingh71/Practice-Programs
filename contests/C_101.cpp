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

        int ls=0,rs=n-1;

        int lo=0,ro=0;
        for(int i=0;i<n;i++){
            if(nums[i]==1){
                lo=1;
                break;
            }if(nums[i]==-1){
                nums[i]=1;
                break;
            }
        }
        for(int i=n-1;i>=0;i--){
            if(nums[i]==1){
                ro=1;
                break;
            }if(nums[i]==-1){
                nums[i]=1;
                break;
            }
        }
        for(int i=0;i<n;i++){
            if(nums[i]==-1){
                nums[i]=0;
            }
        }
        for(int i=0;i<n;i++){
            cout<<nums[i]<<" ";
        }
        cout<<"\n";
    }
    
    return 0;
}
