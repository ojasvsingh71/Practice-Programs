#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n;
        cin>>n;
        vector<int> nums(n);
        unordered_map<int,int> freq;
        for(int i=0;i<n;i++) {
            cin>>nums[i];
            freq[nums[i]]++;
        }
        int bu=0;
        for(auto &i:freq){
            if(i.second==1){
                bu=1;
                break;
            }
        }
        if(bu){
            cout<<-1<<"\n";
            continue;
        }
        int i=0;
        while(i<n){
            int h=freq[nums[i]];
            for(int j=1;j<h;j++){
                cout<<i+j+1<<" ";
            }cout<<i+1<<" ";
            i+=h;
        }
        cout<<"\n";


    }
    
    return 0;
}
