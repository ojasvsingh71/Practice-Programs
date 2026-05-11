#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n;
        long long a;
        cin>>n>>a;
        vector<long long> nums(n);
        int more=0,less=0;
        for(int i=0;i<n;i++) {
            cin>>nums[i];
            if(nums[i]>a) more++;
            else if(nums[i]<a) less++;
        }

        long long b;
        if(more>less) b=a+1;
        else b=a-1;
        

        cout<<b<<"\n";
    }
    
    return 0;
}
