// Maximum Subarray Sum

// Input:  [-2, 1, -3, 4, -1, 2, 1, -5, 4]
// Output: 6
// Explanation: [4, -1, 2, 1] has the largest sum = 6

#include <bits/stdc++.h>
using namespace std;

int main(){
    vector<int> nums = {-2, 1, -3, 4, -1, 2, 1, -5, 4};
    int n=nums.size();

    int ans=nums[0],curr=0;
    
    // O(n)
    for(int i=0;i<n;i++){
        curr+=nums[i];
        if(curr<0) curr=0;
        ans=max(ans,curr);
    }

    cout<<ans<<"\n";
}