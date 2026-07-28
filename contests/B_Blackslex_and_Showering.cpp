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

        int bu=0;
        int maxi=abs(nums[0]-nums[1]);
        for(int i=0;i<n-2;i++){
            if(abs(nums[i]-nums[i+1])+abs(nums[i+1]-nums[i+2])>abs(nums[i]-nums[i+2])){
                if(abs(nums[i]-nums[i+1])+abs(nums[i+1]-nums[i+2])>maxi){
                    maxi=abs(nums[i]-nums[i+1])+abs(nums[i+1]-nums[i+2]);
                    bu=i+1;
                }
            }
        }
        if(abs(nums[n-1]-nums[n-2])>maxi){
            bu=n-1;
        }
        for(int i=bu;i<n-1;i++){
            nums[i]=nums[i+1];
        }
        int ans=0;
        for(int i=1;i<n-1;i++){
            ans+=abs(nums[i]-nums[i-1]);
        }
        
        cout<<ans<<"\n";
    }
     
    return 0;
}
