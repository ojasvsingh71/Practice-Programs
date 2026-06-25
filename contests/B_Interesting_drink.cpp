#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n;
    cin>>n;

    vector<int> nums(n);
    for(int i=0;i<n;i++) cin>>nums[i];

    int q;
    cin>>q;
    sort(nums.begin(),nums.end());

    while(q--){
        int limit;
        cin>>limit;
        int ls=0,rs=n-1;
        int mid;
        while(ls<=rs){
            mid=ls+(rs-ls)/2;
            if(nums[mid]>limit) rs=mid-1;
            else ls=mid+1;
        }
        cout<<ls<<"\n";
    }   


    
    return 0;
}
