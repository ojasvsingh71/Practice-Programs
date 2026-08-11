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
        vector<long long> bu;
        unordered_map<long long,long long> freq;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            freq[nums[i]]++;
            if(freq[nums[i]]==1) bu.push_back(nums[i]);
        }
        sort(bu.begin(),bu.end());
        unordered_map<long long,long long> ans;
        int m=(int)bu.size();
        int hu=0;
        long long curr=0;
        if(m>0 && bu[0]!=0) hu=1;
        for(int i=1;i<m;i++){
            if(bu[i] > curr && (bu[i]-curr)%freq[bu[i-1]]==0 ){
                ans[bu[i-1]]=(bu[i]-curr)/freq[bu[i-1]];
            }else{
                hu=1;
                break;
            }
            curr+=(ans[bu[i-1]]*freq[bu[i-1]]);
        }
        if(m>0) ans[bu[m-1]]=ans[bu[m-2]]+1;

        for(int i=1;i<m;i++){
            if(ans[bu[i]]<=ans[bu[i-1]]){
                hu=1;
                break;
            }
        }

        if(hu) {
            cout<<-1<<"\n";
            continue;
        }
        // vector<long long> fin={ans[nums[0]]};
        for(int i=0;i<n;i++){
            cout<<(ans[nums[i]])<<" ";
            
        }
        // for(long long &i:fin){
        //     cout<<i<<" ";
        // }
        cout<<"\n";
    }
    
    return 0;
}
