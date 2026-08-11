#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n;
        int k;
        cin>>n;
        cin>>k;
        string s;
        cin>>s;

        int odd=0,even=0;
        for(int i=0;i<2*n;i++){
            if(s[i]=='1'){
                if(s[(i+1)%(2*n)]=='0') {
                    if(i%2==0) even++;
                    else odd++;
                }else{
                    if(i%2==0) odd++;
                    else even++;
                }
            }
        }
        cout<<even<<" "<<odd<<"\n";


    }
    
    return 0;
}
