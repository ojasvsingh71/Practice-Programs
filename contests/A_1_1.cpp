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
        string nums;
        cin>>nums;

        int one=0;
        for(int i=1;i<n-1;i++){
            if(nums[i]=='0' && nums[i-1]=='1' && nums[i+1]=='1') nums[i]='1';
        }
        for(char c:nums){
            if(c=='1') one++;
        }
        int maxi=one;
        for(int i=1;i<n-1;i++){
            if(nums[i]=='1' && nums[i-1]=='1' && nums[i+1]=='1') nums[i]='0';
        }
        one=0;
        for(char c:nums){
            if(c=='1') one++;
        }
        cout<<one<<" "<<maxi<<"\n";
    }
    
    return 0;
}
