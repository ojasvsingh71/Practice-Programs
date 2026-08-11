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
        for(int i=0;i<n;i++){
            cin>>nums[i];
        }
        int sw=1;
        int ans=n;

        int one=0,two=0;
        vector<pair<int,int>> bu;
        for(int i=1;i<n;i++){
            if(nums[i]==nums[i-1]){
                if(i-2==0) one++;
                if(i-2>0){
                    if(nums[i-3]!=nums[i]) one++;
                }
                int rs=i+1;
                while(rs<n && nums[rs]==nums[i]) rs++;
                ans-=(rs-i);
                if(rs==n-1) one++;
                if(rs<n-1){
                    if(nums[rs+1]! =nums[i]) one++;
                }

                if(bu.size()>0 && bu.back().second==i-2) two++;
                bu.push_back({i-1,rs-1});
                i=rs-1;

            }
        }
        if(two) ans+=2;
        else if(one) ans++;
        // cout<<one<<"--"<<two<<"\t";
        cout<<ans<<"\n";
    }
    
    return 0;
}
