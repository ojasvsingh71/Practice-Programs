#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n;
    cin>>n;
    vector<int> keys(n),freq(n);
    for(int i=0;i<n;i++) cin>>keys[i];
    for(int i=0;i<n;i++) cin>>freq[i];

    
    vector<vector<int>> c(n,vector<int>(n,INT_MAX));
    
    for(int i=0;i<n;i++){
        c[i][i]=freq[i];
    }

    for(int len=2;len<=n;len++){
        for(int i=0;i<n-len+1;i++){
            int j=len+i-1;
            int sum=0;
            for(int k=i;k<=j;k++) sum+=freq[k];
            for(int r=i;r<=j;r++){
                int left=(r-1>=i) ? c[i][r-1] : 0;
                int right=(r+1<=j) ? c[r+1][j] : 0;
                c[i][j]=min(c[i][j],sum+left+right);
            }
        }
    }
    
    cout<<c[0][n-1];

    return 0;
}





// 3
// 10 12 20
// 34 8 50