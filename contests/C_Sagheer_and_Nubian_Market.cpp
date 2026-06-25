#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n,total;
    cin>>n>>total;

    vector<int> nums(n);
    for(int i=0;i<n;i++) cin>>nums[i];

    int ls=0,rs=n-1;
    int ans=0;
    long long cost=0;
    while(ls<=rs){
        int mid=ls+(rs-ls)/2;

        vector<long long> bu(n);
        for(int i=0;i<n;i++){
            bu[i]=(long long)nums[i]+(long long)(i+1)*(mid+1);
        }

        sort(bu.begin(),bu.end());
        
        long long sum=0;
        for(int i=0;i<=mid;i++) sum+=bu[i];

        if(sum<=total){
            ans=mid+1,cost=sum;
            ls=mid+1;
        }else rs=mid-1;
    }
    cout<<ans<<" "<<cost<<"\n";

    return 0;
}
