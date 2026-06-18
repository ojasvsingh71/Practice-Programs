#include <bits/stdc++.h>
using namespace std;

// bool ispal(long long n){
//     vector<int> hu;
//     while(n>0){
//         hu.push_back(n%10);
//         n/=10;
//     }
//     int m=hu.size();
//     for(int i=0;i<m/2;i++){
//         if(hu[i]!=hu[m-i-1]) return false;
//     }
//     return true;
// }

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        long long n;
        cin>>n;

        long long bu=n%12;
        if(bu==10 && n>=22){
            bu=22;
        }

        if(bu==10) cout<<-1<<"\n";
        else cout<<bu<<" "<<n-bu<<"\n";

        // for(int i=1;i<12;i++){
        //     int bu=i;
        //     while(!ispal(bu)){
        //         bu+=12;
        //     }
        //     cout<<bu<<" ";
        // }
        // cout<<"\n";

    }
    // cout<<(192<<1);
    
    return 0;
}
