#include <bits/stdc++.h>
using namespace std;

int solve(int i,int j,string s){
    if(i>j) return 0;
    if(i==j) return 1;
    if(s[i]==s[j]) return 2+solve(i+1,j-1,s);

    return max(solve(i+1,j,s),solve(i,j-1,s));
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    string s;
    cin>>s;

    cout<<solve(0,s.size()-1,s);
    
    return 0;
}
