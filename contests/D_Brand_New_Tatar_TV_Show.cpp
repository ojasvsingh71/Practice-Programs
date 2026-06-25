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
        map<int,int> freq;


        for(int i=0;i<n;i++) {
            cin>>nums[i];
            freq[nums[i]]++;
        }
        sort(nums.begin(),nums.end());

        vector<vector<int>> groups;

        
        for(int i=0;i<n;i++){
            int start=nums[i];
            vector<int> curr={start};
            unordered_set<int> s;
            s.insert(start);
            int rs=i+1;
            while(rs<n && nums[rs]-curr.back()<=k) {
                if(!s.count(nums[rs])){
                    curr.push_back(nums[rs]);
                    s.insert(nums[rs]);
                }
                rs++;
            }
            groups.push_back(curr);
            i=rs-1;
        }

        int ans=0;
        for(auto i:groups){
            if(i.size()>1 || (i.size()==1 && freq[i[0]]%2==0)){
                ans=1;
                break;
            }
        }

        if(ans) cout<<"YES\n";
        else cout<<"NO\n";

        // for(auto i:freq){
        //     int start=i.first;
        //     vector<int> curr={start};

        // }



    }
    
    return 0;
}
