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
        vector<long long> nums(n);
        long long ans=0;
        long long one=0;
        long long fours=0;
        long long pair=0;
        for(int i=0;i<n;i++) {
            cin>>nums[i];
            if(nums[i]==1) one++;
            else {
                pair++;
                ans+=nums[i];
                if(nums[i]>=4){
                    long long num=nums[i];
                    fours+=1;
                    num-=4;
                    fours+=num/2;
                }
            }
        }


        // cout<<fours<<"-\n";
        if(ans==2){
            if(one) cout<<ans+1<<"\n";
            else cout<<0<<"\n";
        }else if(ans==3){
            if(one) cout<<ans+1<<"\n";
            else cout<<ans<<"\n";
        }
        else{
            if(one<=fours){
                cout<<ans+one<<"\n";
            }
            else{
                if(pair==1 && one) ans++;
                cout<<ans+fours<<"\n";
            }
        }

    }
    
    return 0;
}
