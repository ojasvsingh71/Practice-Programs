#include<bits/stdc++.h>
using namespace std;

void radix_sort(vector<int>& nums,int n){
    int maxi=*max_element(nums.begin(),nums.end());
    int len=0;
    while(maxi>0) {
        len++;
        maxi/=10;
    }for(int i=0;i<len;i++){
        map<int,vector<int>> mp;
        for(int j:nums){
            mp[(j/(int)pow(10,i))%10].push_back(j);
        }int k=0;

        for(auto j=mp.begin();j!=mp.end();j++){
            sort(j->second.begin(),j->second.end());
            for(int l:j->second){
                nums[k++]=l;
            }
        }
    }
}

int main(){
    int n;
    cin>>n;
    vector<int> nums(n);
    for(int i=0;i<n;i++) cin>>nums[i];
    
    radix_sort(nums,n);

    for(int i:nums) cout<<i<<" ";
}