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
        vector<string> nums(n);
        for(int i=0;i<n;i++){
           cin>>nums[i];
        }
        string s;
        s+=nums[0];
        for(int i=1;i<n;i++){
            if((nums[i]+s)>(s+nums[i])) s=s+nums[i];
            else s=nums[i]+s;
        }
        cout<<s<<"\n";
        
    }
    
    return 0;
}
