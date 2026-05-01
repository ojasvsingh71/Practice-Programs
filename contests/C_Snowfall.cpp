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
        for(int i=0;i<n;i++) cin>>nums[i];
        vector<long long> otwo,othree,both,other;
        for(long long i:nums){
            if(i%6==0) both.push_back(i);
            else if(i%2==0) otwo.push_back(i);
            else if(i%3==0) othree.push_back(i);
            else other.push_back(i);
        }
        for(long long i:both) cout<<i<<" ";
        for(long long i:otwo) cout<<i<<" ";
        for(long long i:other) cout<<i<<" ";
        for(long long i:othree) cout<<i<<" ";
        cout<<"\n";
    }
    
    return 0;
}
