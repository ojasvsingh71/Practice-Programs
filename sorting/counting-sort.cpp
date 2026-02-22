#include <bits/stdc++.h>
using namespace std;

void counting_sort(vector<int> &nums,int n){
    int k=*max_element(nums.begin(),nums.end());
    vector<int> count(k+1,0);
    for(int i:nums){
        count[i]++;
    }
    int j=0;
    for(int i=0;i<=k;i++){
        while(count[i]--){
            nums[j++]=i;
        }
    }
}

int main(){
    int n;
    cin >> n;
    vector<int> nums(n);
    for (int i = 0; i < n; i++){
        cin >> nums[i];
    }

    counting_sort(nums,n);

    for (int i : nums){
        cout << i << " ";
    }
}