#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n,m;
        cin>>n>>m;
        vector<int> nums(n),b(m);
        long long sum=0;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            sum+=nums[i];
        }
        for(int i=0;i<m;i++){
            cin>>b[i];
        }
        vector<vector<long long>> index(n);
        long long pos=0,neg=0;
        for(int i=0;i<n;i++){
            if(nums[i]>0) pos+=nums[i];
            else neg+=(-nums[i]);
            index[i]={pos,neg};
        }
        int id=-1;
        long long anu=INT_MIN;
        for(int i=0;i<m;i++){
            int j=b[i]-1;
            if(index[j][1]-index[j][0]>anu){
                anu=index[j][1]-index[j][0];
                id=j;
            }
        }
        long long ans=anu;
        for(int i=id+1;i<n;i++){
            ans+=nums[i];
        }
        cout<<max(sum,ans)<<"\n";

    }
    
    return 0;
}
