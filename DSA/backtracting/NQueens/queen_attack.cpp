#include <bits/stdc++.h>
using namespace std;

void explore(int row,int col,vector<vector<int>>& board,int n,int m,vector<vector<int>>& ans){
    int dx[]={1,1,-1,-1,1,-1,0,0};
    int dy[]={1,-1,1,-1,0,0,1,-1};

    for(int i=0;i<8;i++){
        int x=row+dx[i];
        int y=col+dy[i];

        while(x>=0 && y>=0 && x<n && y<m){
            if(board[x][y]==1) {
                ans[row][col]++;
                break;
            }x+=dx[i];
            y+=dy[i];
        }
    }
}

void solve(int row,vector<vector<int>> & board,int n,int m,vector<vector<int>>& ans){
    
    for(int i=row;i<n;i++){
        for(int col=0;col<m;col++){
            explore(i,col,board,n,m,ans);
        }
    }
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n,m;
    cin>>n>>m;

    vector<vector<int>> board(n,vector<int>(m));
    vector<vector<int>> ans(n,vector<int>(m,0));

    for(int i=0;i<n;i++){
        for(int j=0;j<m;j++){
            cin>>board[i][j];
        }
    }

    solve(0,board,n,m,ans);

    for(int i=0;i<n;i++){
        for(int j=0;j<m;j++){
            cout<<ans[i][j]<<" ";
        }cout<<"\n";
    }
    
    return 0;
}



// 3 3
// 0 1 0
// 1 0 0
// 0 0 1