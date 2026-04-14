#include <bits/stdc++.h>
using namespace std;

void shell_sort(vector<int> &nums, int n){
    for(int gap=n/2;gap>=1;gap/=2){
        for(int j=gap;j<n;j++){
            for(int i=j-gap;i>=0;i-=gap){
                if(nums[i]>nums[i+gap]){
                    swap(nums[i],nums[i+gap]);
                }
            }
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

    shell_sort(nums, n);

    for (int i : nums){
        cout << i << " ";
    }
}