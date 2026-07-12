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
        int one=0,two=0,three=0;
        int stage=1;
        int bu=0;
        for(int i=0;i<n;i++){
            if(stage==1){
                if(nums[i]==1) one++;
                else if(nums[i]==2) two++;
                else three++;
                if(one>=two+three) {
                    stage++;
                    int rs=i+1;
                    while(rs<n && one>=two+three && nums[rs]==3) {
                        three++;
                        rs++;
                    }
                    i=rs-1;
                    one=two=three=0;
                }
            }else if(stage==2){
                if(nums[i]==1) one++;
                else if(nums[i]==2) two++;
                else three++;
                if(one+two>=three) stage++;
            }else{
                bu=1;
            }
        }
        if(stage==3 && bu) cout<<"YES\n";
        else cout<<"NO\n";
    }
    
    return 0;
}
