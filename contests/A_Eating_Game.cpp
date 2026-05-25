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
        unordered_map<int,int> freq;
        int maxi=0;
        vector<int> nums(n);
        for(int i=0;i<n;i++){
            cin>>nums[i];
            maxi=max(maxi,nums[i]);
            freq[nums[i]]++;
        }
        
        cout<<freq[maxi]<<"\n";
    }
    
    return 0;
}
