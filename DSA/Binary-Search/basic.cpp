#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int key=8;

    vector<int> nums(10);
    for(int i=0;i<10;i++) nums[i]=i+1;

    int ls=0,rs=9;

    for(int i:nums) cout<<i<<" ";
    cout<<"\n";
    while(ls<=rs){
        int mid=ls+(rs-ls)/2;

        if(nums[mid]==key) {
            cout<<mid<<"\n";
            return 0;
        }
        else if(nums[mid]>key) rs=mid-1;
        else ls=mid+1;
    }
    cout<<-1<<"\n";
    
    return 0;
}
