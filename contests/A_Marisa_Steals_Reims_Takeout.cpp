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
        int zero=0,one=0,two=0;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            if(nums[i]==0) zero++;
            else if(nums[i]==1) one++;
            else two++;
        }
        long long ans=zero;
        ans+=min(one,two);
        if(one>two) {
            one-=two;
            two=0;
        }else {
            two-=one;
            one=0;
        }
        cout<<ans+two/3+one/3<<"\n";
    }
    
    return 0;
}
