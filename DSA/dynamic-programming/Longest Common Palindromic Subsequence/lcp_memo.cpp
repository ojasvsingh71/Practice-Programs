#include <bits/stdc++.h>
using namespace std;

vector<vector<int>> memo;

int solve(int i,int j,string s){
    if(i>j) return 0;
    if(i==j) return 1;

    if(memo[i][j]!=-1) return memo[i][j];

    if(s[i]==s[j]) return memo[i][j]=2+solve(i+1,j-1,s);
    return memo[i][j]=max(solve(i+1,j,s),solve(i,j-1,s));
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    string s;
    cin>>s;

    int n=s.size();
    memo.resize(n,vector<int>(n,-1));

    cout<<solve(0,n-1,s);
    
    return 0;
}
