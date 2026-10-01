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
        // int ans=0;
        int odd=0,e_odd=0,e_even=0;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            if(nums[i]%2!=0){
                odd++;
            }else{
                if((nums[i]/2)%2==0) e_even++;
                else e_odd++;
            }
        }
        int ans=max(odd,max(e_even,e_odd));
        cout<<ans<<"\n";
    }
    
    return 0;
}
