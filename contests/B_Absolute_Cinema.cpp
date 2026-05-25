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

        vector<long long> a(n),b(n);
        // vector<long long> nums(2*n);
        long long sum=0;
        for(int i=0;i<n;i++) cin>>a[i];
        long long sec=0;
        
        for(int i=0;i<n;i++) cin>>b[i];
        // for(int i=0;i<2*n;i++) cin>>nums[i];

        // sort(nums.rbegin(),nums.rend());

        
        for(int i=0;i<n;i++){
            if(a[i]>b[i]) swap(a[i],b[i]);
            sum+=b[i];
            sec=max(sec,a[i]);
        }
        cout<<sum+sec<<"\n";

    }
    
    return 0;
}
