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
        int sum=0;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            sum+=nums[i];
        }
        sum=abs(sum);
        
        if(sum%4==0) cout<<"YES\n";
        else cout<<"NO\n";
    }
    
    return 0;
}
