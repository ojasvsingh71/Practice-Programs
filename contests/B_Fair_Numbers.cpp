#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        long long n;
        cin>>n;

        while(true){
            // int bu=0;
            long long temp=n;
            vector<int> curr;
            while(temp>0){
                curr.push_back(temp%10);
                temp/=10;
            }
            int m=curr.size();
            temp=n;
            // int mini=10;
            for(int i=m-1;i>=0;i--){
                if(curr[i]!=0 && temp%curr[i]!=0){
                    n++;
                    break;
                }
            }
            if(temp==n) break;
        }
        cout<<n<<"\n";
    }
    
    return 0;
}
