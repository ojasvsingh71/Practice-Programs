#include<bits/stdc++.h>
using namespace std;

int main(){
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int t;
    cin>>t;
    while(t--){
        int n,k;
        cin>>n>>k;

        vector<int> nums(n);
        for(int i=0;i<n;i++){
            cin>>nums[i];
        }
        if(is_sorted(nums.begin(),nums.end())){
            cout<<"YES\n";
        }else{
            if(k==1) cout<<"NO\n";
            else{
                cout<<"YES\n";
            }
        }
    }
}