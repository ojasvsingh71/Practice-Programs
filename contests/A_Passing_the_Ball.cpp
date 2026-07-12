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
        vector<char> s(n);
        int bu=-1;
        for(int i=0;i<n;i++){
            cin>>s[i];
            if(s[i]=='L' && bu==-1) bu=i;
        }
        cout<<bu+1<<"\n";
    }
    
    return 0;
}
