#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        long long n,k;
        cin>>n>>k;

        int ls=0,rs=2e9;

        while(ls<rs){
            long long mid=ls+(rs-ls)/2;

            long long cnt=mid-mid/n;
            if(cnt>=k) rs=mid;
            else ls=mid+1;
        }
        cout<<rs<<"\n";
    }
    
    return 0;
}
