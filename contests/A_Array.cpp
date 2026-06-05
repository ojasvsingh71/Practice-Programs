#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
        int n;
        cin>>n;
        vector<int> nums(n);
        
        vector<int> pos,neg,zero;
        for(int i=0;i<n;i++){
            cin>>nums[i];

            if(nums[i]==0) zero.push_back(0);
            else if(nums[i]<0) neg.push_back(nums[i]);
            else pos.push_back(nums[i]);
        }

        if(pos.size()==0){
            pos.push_back(neg.back());
            neg.pop_back();
            pos.push_back(neg.back());
            neg.pop_back();
        }
        if(neg.size()%2==0){
            zero.push_back(neg.back());
            neg.pop_back();
        }

        cout<<neg.size()<<" ";
        for(int i:neg) cout<<i<<" ";
        cout<<"\n"<<pos.size()<<" ";
        for(int i:pos) cout<<i<<" ";
        cout<<"\n"<<zero.size()<<" ";
        for(int i:zero) cout<<i<<" ";
        cout<<"\n";
    
    
    return 0;
}
