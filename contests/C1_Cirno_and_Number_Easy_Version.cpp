#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n;
        long long a;
        cin>>a>>n;
        vector<int> nums(n);
        for(int i=0;i<n;i++){
            cin>>nums[i];
        }

        long long b;
        string s=to_string(a);
        
        string ans;
        for(char c:s){
            int digit=c-'0';
            int fst=0,sec=0;
            if(digit>nums[0]){
                fst=min(digit-nums[0],10-digit+nums[0]);
            }else{
                fst=min(nums[0]-digit,10-nums[0]+digit);
            }
            if(digit>nums[1]){
                sec=min(digit-nums[1],10-digit+nums[1]);
            }else{
                sec=min(nums[1]-digit,10-nums[1]+digit);
            }
            if(fst<sec) ans.push_back('0'+nums[0]);
            else ans.push_back('0'+nums[1]);
        }
        string ans2="";
        int m=s.size();
        for(int i=1;i<m;i++){
            int digit=s[i]-'0';
            int fst=0,sec=0;
            if(digit>nums[0]){
                fst=min(digit-nums[0],10-digit+nums[0]);
            }else{
                fst=min(nums[0]-digit,10-nums[0]+digit);
            }
            if(digit>nums[1]){
                sec=min(digit-nums[1],10-digit+nums[1]);
            }else{
                sec=min(nums[1]-digit,10-nums[1]+digit);
            }
            if(fst<sec) ans2.push_back('0'+nums[0]);
            else ans2.push_back('0'+nums[1]);
        }
        b=stoll(ans);
        long long b2=LLONG_MAX;
        if(!ans2.empty()) b2=stoll(ans2);
        cout<<b<<"---"<<b2<<"-> ";
        cout<<min(abs(a-b),abs(a-b2))<<"\n";
    }
    
    return 0;
}
