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
        int pos=0;
        for(int i=0;i<n;i++) {
            cin>>nums[i];
            if(nums[i]>0) pos=1;
        }
        if(!pos){
            cout<<0<<"\n";
            continue;
        }

        int par=0;
        int i=n-1;
        long long ans=0;
        vector<long long> bu;
        while(i>=0){
            if(par==0){
                while(i>=0 && nums[i]<=0) i--;
                if(i>=0) {
                    bu.push_back(i);
                    par=1-par;
                    ans++;
                }
            }else{
                while(i>=0 && nums[i]>=0) i--;
                if(i>=0) {
                    bu.push_back(i);
                    par=1-par;
                    ans++;
                }
            }
        }
        cout<<ans<<"\n";
        for(long long j:bu){
            cout<<j+1<<" ";
        }
        cout<<"\n";
    }
    
    return 0;
}
