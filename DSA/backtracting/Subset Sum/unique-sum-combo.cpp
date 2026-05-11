#include <bits/stdc++.h>
using namespace std;

set<vector<int>> seen;
vector<vector<int>> ans;

void unique_sum_combo(int i,vector<int>& nums,int tar,vector<int> curr){
    if(tar==0){
        if(!seen.count(curr)){
            seen.insert(curr);
            ans.push_back(curr);
        }
        return ;
    }if(i==nums.size() || tar<0) return ;
    curr.push_back(nums[i]);
    unique_sum_combo(i+1,nums,tar-nums[i],curr);
    unique_sum_combo(i,nums,tar-nums[i],curr);
    curr.pop_back();
    unique_sum_combo(i+1,nums,tar,curr);
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    string s;
    getline(cin,s);
    vector<int> nums;
    stringstream ss(s);
    string temp;
    while(ss>>temp){
        nums.push_back(stoi(temp));
    }

    int tar;
    cin>>tar;

    unique_sum_combo(0,nums,tar,{});
    
    sort(ans.begin(),ans.end());
    cout<<"[";
    for(int i=0;i<ans.size();i++){
        cout<<"[";
        for(int j=0;j<ans[i].size();j++){
            cout<<ans[i][j];
            if(j<ans[i].size()-1) cout<<", ";
        }
        cout<<"]";
        if(i<ans.size()-1) cout<<", ";
    }
    cout<<"]";

    return 0;
}




// 2 3 5	
// 8