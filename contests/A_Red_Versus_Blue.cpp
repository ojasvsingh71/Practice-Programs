#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n,r,b;
        cin>>n>>r>>b;
        int bu=r/(b+1);
        int rem=r%(b+1);

        while(r>0 && b>0){
            for(int j=0;j<bu && r>0;j++){
                cout<<"R";
                r--;
            }if(rem>0) {
                cout<<"R";
                rem--;
                r--;
            }
            if(b>0) {
                cout<<"B";
                b--;
            }
        }
        while(r>0) {
            cout<<"R";
            r--;
        }
        cout<<"\n";
    }
    
    return 0;
}
