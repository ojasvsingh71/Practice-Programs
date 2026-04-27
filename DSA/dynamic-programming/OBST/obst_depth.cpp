#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n,d;
    cin>>n>>d;
    vector<int> keys(n),freq(n);
    for(int i=0;i<n;i++) cin>>keys[i];
    for(int i=0;i<n;i++) cin>>freq[i];

    vector<vector<vector<int>>> c(n,vector<vector<int>>(n,vector<int>(d+1,INT_MAX)));

    for(int i=0;i<n;i++){
        for(int h=1;h<=d;h++){
            c[i][i][h]=freq[i];
        }
    }

    for(int len=2;len<=n;len++){
        for(int i=0;i<n-len+1;i++){
            int j=len+i-1;
            int sum=0;
            for(int k=i;k<=j;k++) sum+=freq[k];
            for(int h=1;h<=d;h++){
                for(int r=i;r<=j;r++){
                    int left=0,right=0;
                    if(r-1>=i){
                        if(h-1==0 || c[i][r-1][h-1]==INT_MAX) continue;
                        left=c[i][r-1][h-1];
                    }
                    if(r+1<=j){
                        if(h-1==0 || c[r+1][j][h-1]==INT_MAX) continue;
                        right=c[r+1][j][h-1];
                    }
                    c[i][j][h]=min(c[i][j][h],sum+left+right);
                }
            }
        }
    }

    cout<<c[0][n-1][d];
    
    return 0;
}




// 3 2
// 10 12 20
// 34 8 50