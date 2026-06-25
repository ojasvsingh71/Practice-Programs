#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);

    int t;
    cin>>t;
    while(t--){
        int a,b;
        cin>>a>>b;
        
        vector<int> nums;
        int  bu=0;
        int ans=INT_MAX;
        if(b==1) {
            b++;
            bu=1;   
        }

        while(true){
            int temp=a;
            int cnt=0;
            while(temp>0){
                temp/=b;
                cnt++;
            }
            b++;
            ans=min(ans,(int)nums.size()+cnt);
            nums.push_back(cnt);
            if(nums.size()>nums[0]) break;
        }
        cout<<bu+ans<<"\n";

        
    }
    
    return 0;
}
