#include <bits/stdc++.h>
using namespace std;

bool found=false;
int n;
vector<long long> ans;
unordered_map<long long,int> freq; 

void branch(int i){
    if(found) return ;
    if(ans.size()==n){
        found=true;
        // cout<<"GOT";
        return ;
    }
    // cout<<i<<" ";
    long long curr=ans.back();
    if(curr%3==0 && freq[curr/3]>0){
        freq[curr/3]--;
        ans.push_back(curr/3);
        branch(i+1);
        if(found==true) return ;
        freq[curr/3]++;
        ans.pop_back();
    }
    if(freq[curr*2]>0){
        freq[curr*2]--;
        ans.push_back(curr*2);
        branch(i+1);
        if(found==true) return ;
        freq[curr*2]++;
        ans.pop_back();
    }
    return ;
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    cin>>n;
    vector<long long> nums(n);
    
    for(int i=0;i<n;i++) {
        cin>>nums[i];
        freq[nums[i]]++;
    }

    for(int i=0;i<n;i++){
        ans.push_back(nums[i]);
        freq[nums[i]]--;
        branch(0);
        if(found) break;
        ans.pop_back();
        freq[nums[i]]++;
    }

    for(long long i:ans){
        cout<<i<<" ";
    }
    
    return 0;
}
