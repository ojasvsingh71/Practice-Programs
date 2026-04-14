#include<bits/stdc++.h>
using namespace std;

void bucket_sort(vector<float>& nums,int n){
    map<int,vector<float>> mp;
    for(float i:nums){
        int index=(i*10>9) ? 9 :i*10;
        mp[index].push_back(i);
    }int k=0;
    for(auto i=mp.begin();i!=mp.end();i++){
        sort(i->second.begin(),i->second.end());
        for(float j:i->second) nums[k++]=j;
    }
}

int main(){
    int n;
    cin>>n;
    vector<float> nums(n);
    for(int i=0;i<n;i++) cin>>nums[i];
    
    bucket_sort(nums,n);

    for(float i:nums) cout<<i<<" ";
}