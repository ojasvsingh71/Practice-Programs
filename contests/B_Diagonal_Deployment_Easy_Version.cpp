#include<bits/stdc++.h>
using namespace std;

int main(){
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int t;
    cin>>t;
    while(t--){
        int n,m,k;
        cin>>n>>m>>k;

        int count=0;
        
        vector<int> nums;

        int mn=min(n,m);
        int mx=max(n,m);
        for(int i=0;i<mx-mn+1;i++){
            nums.push_back(mn);
        }

        for(int i=mn-1;i>0;i--){
            nums.push_back(i);
            nums.push_back(i);
        }

        for(int i:nums){
            if(k<=0) break;
            k-=i;
            count++;
        }
        cout<<count<<"\n";

        
    }
}