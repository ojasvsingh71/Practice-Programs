#include <bits/stdc++.h>
using namespace std;

string a,b;

int lcs(int i,int j){
    if(i==a.size() || j==b.size()) return 0;
    else if(a[i]==b[j]) return 1+lcs(i+1,j+1);
    else return max(lcs(i+1,j),lcs(i,j+1));
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    cin>>a>>b;

    cout<<lcs(0,0);
    
    return 0;
}
