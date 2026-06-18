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
        string s;
        cin>>s;

        stack<char> stk;
        for(char c:s){
            if(!stk.empty() && stk.top()=='(' && c==')') stk.pop();
            else stk.push(c);
        }
        cout<<stk.size()/2<<"\n";

    }
    
    return 0;
}
