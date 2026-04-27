#include <bits/stdc++.h>
using namespace std;

string a,b;
vector<vector<int>> memo;

int lcs(int i,int j){
    if(memo[i][j]!=-1) return memo[i][j];

    else if(i==a.size() || j==b.size()){
        memo[i][j]=0;
        return 0;
    }

    else if(a[i]==b[j]){
        memo[i][j]=1+lcs(i+1,j+1);
        return memo[i][j];
    }
    else{
        memo[i][j]=max(lcs(i+1,j),lcs(i,j+1));
        return memo[i][j];
    }
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    cin>>a>>b;
    memo.resize(a.size()+1,vector<int>(b.size()+1,-1));
    
    cout<<lcs(0,0);
    
    return 0;
}
