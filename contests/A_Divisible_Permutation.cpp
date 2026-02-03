#include<bits/stdc++.h>
using namespace std;

int main(){
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int t;
    cin>>t;
    while(t--){
        int n;
        cin>>n;
        vector<int> nums(n+1);
        nums[n]=n;
        nums[n-1]=1;
        int i=n-1;
        unordered_set<int> seen;
        seen.insert(n);
        seen.insert(1);
        while(i>0){
            for(int j=n-1;j>0;j--){
                if(!seen.count(j) && abs(j-nums[i+1])%i==0){
                    nums[i]=j;
                    seen.insert(j);
                    break;
                }
            }
            i--;
        }
        for(int i=1;i<=n;i++) cout<<nums[i]<<" ";
        cout<<"\n";
    }
}