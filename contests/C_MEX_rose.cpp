#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n,k;
        cin>>n>>k;
        vector<int> nums(n);
        unordered_map<int,int> freq;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            freq[nums[i]]++;
        }
        int ans=0;
        for(int i=0;i<k;i++){
            if(!freq.count(i)){
                if(freq[k]>0) freq[k]--;
                ans++;
            }
        }
        cout<<ans+freq[k]<<"\n";
    }
    
    return 0;
}
