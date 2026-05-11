#include<bits/stdc++.h>
using namespace std;

void tar_subset(vector<int>& nums,int tar,int i,vector<int> sub){
    if(tar==0){
        cout<<"\n";
        for(int j:sub) cout<<j<<" ";
        cout<<"\n";
        return ;
    }
    if(i==nums.size() || tar<0) return ;
    sub.push_back(nums[i]);
    tar_subset(nums,tar-nums[i],i+1,sub);
    sub.pop_back();
    tar_subset(nums,tar,i+1,sub);
}

int main(){
    int n;
    cin>>n;
    vector<int> nums(n);
    for(int i=0;i<n;i++) cin>>nums[i];
    int tar;
    cin>>tar;

    tar_subset(nums,tar,0,{});
}