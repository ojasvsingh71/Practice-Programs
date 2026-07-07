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
        vector<int> nums(n),even,odd;
        vector<int> bu(m);
        int ebu=0,obu=0;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            if(i%2!=0) even.push_back(nums[i]);
            else odd.push_back(nums[i]);
        }
        for(int i=0;i<m;i++){
            cin>>bu[i];
            if(bu[i]%2==0) ebu++;
            else obu++;
        }
        sort(even.rbegin(),even.rend());
        sort(odd.rbegin(),odd.rend());
        int i=0;
        while(ebu-- && i<even.size()){
            // cout<<even[i]<<" ";
            i++;
            if(even[i]<0) break;
        }
        int j=0;
        while(obu-- && j<odd.size()){
            // cout<<odd[j]<<" ";
            j++;
            if(odd[j]<0) break;
        }
        long long ans=0;
        while(i<even.size()) ans+=even[i++];
        while(j<odd.size()) ans+=odd[j++];
        cout<<ans<<"\n";
    }
    
    return 0;
}
