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
        // unordered_map<int,int> freq;
        int z=0;
        for(int i=0;i<n;i++){
            cin>>nums[i];
            if(nums[i]==0) z++
        }
        if(z==1){
            cout<<"NO\n";
            continue;
        }else{
            cout<<"YES\n";
            int bu=0;
            for(int i=0;i<n;i++){
                if(nums[i]==0){
                    if(bu){
                        cout<<"A";
                    }else{
                        cout<<"B";
                    }bu=1-bu;
                }else cout<<"C";
            }
        }
        cout<<"\n";
    }
    
    return 0;
}
