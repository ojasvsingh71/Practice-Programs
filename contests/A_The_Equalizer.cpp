#include<bits/stdc++.h>
using namespace std;

int main(){
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int t;
    cin>>t;
    while(t--){
        int n,k;
        cin>>n>>k;
        vector<int> nums(n);
        long long sum=0;
        for(int i=0;i<n;i++) {
            cin>>nums[i];
            sum+=nums[i];
        }
        if(sum%2!=0 || (sum+n*k)%2==0) cout<<"YES\n";
        else cout<<"NO\n";

    }
}