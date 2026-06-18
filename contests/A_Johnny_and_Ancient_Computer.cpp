#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        long long a,b;
        cin>>a>>b;

        long long aa=a,bb=b;
        vector<int> nums;
        vector<int> tar;

        int a_one=0,b_one=0;
        while(a>0){
            nums.push_back(a%2);
            if(a%2) a_one++;
            a/=2;
        }
        while(b>0){
            tar.push_back(b%2);
            if(b%2) b_one++;
            b/=2;
        }
        if(a_one!=b_one) cout<<-1<<"\n";
        else{
            // for(int i=0;i<nums.size();i++){
            //     cout<<nums[i];
            // }
            // cout<<"\n";
            // for(int i=0;i<tar.size();i++){
            //     cout<<tar[i];
            // }cout<<"\n";
            int ans=0;
            for(int i=0;i<nums.size();i++){
                if(nums[i]!=tar[i]){
                    if(nums[i]==1){
                        int j=i;
                        while(j<tar.size() && tar[j]!=1) j++;
                        int diff=j-i;
                        if(diff>=3){
                            ans+=diff/3;
                            aa=(aa<<diff/3*3);
                            diff-=(diff/3)*3;
                        }if(diff>=2){
                            ans+=diff/2;
                            aa=(aa<<diff/2*2);
                            diff-=(diff/2)*2;
                        }if(diff>=1){
                            ans+=diff;
                            aa=(aa<<diff);
                        }
                    }else{
                        int j=i;
                        while(j<nums.size() && nums[j]!=1) j++;
                        int diff=j-i;
                        if(diff>=3){
                            ans+=diff/3;
                            bb=(bb<<diff/3*3);
                            diff-=(diff/3)*3;
                        }if(diff>=2){
                            ans+=diff/2;
                            bb=(bb<<diff/2*2);
                            diff-=(diff/2)*2;
                        }if(diff>=1){
                            ans+=diff;
                            bb=(bb<<diff);
                        }
                        
                    }break;
                }
            }
            // cout<<aa<<" "<<bb<<"\n";
            if(aa!=bb) cout<<-1<<"\n";
            else cout<<ans<<"\n";
        }
    }
    
    return 0;
}
