#include <bits/stdc++.h>
using namespace std;

vector<vector<int>> board;
vector<vector<int>> ans;

int found=0;

bool isSafe(int row,int col,int n){
    int dx[]={-1,-1,-1};
    int dy[]={0,-1,1};

    for(int i=0;i<3;i++){
        int x=row+dx[i];
        int y=col+dy[i];
        while(x>=0 && y>=0 && x<n && y<n){
            if(board[x][y]) return false;
            x+=dx[i];
            y+=dy[i];
        }
    }return true;
}

void solve(int row,int n){
    if(row==n){
        found=1;
        vector<int> curr;
        for(int j=0;j<n;j++){
            for(int i=0;i<n;i++){
                if(board[i][j]) {
                    curr.push_back(i);
                }
            }
        }
        ans.push_back(curr);
        return ;
    }

    
        for(int col=0;col<n;col++){
            if(isSafe(row,col,n)){
                board[row][col]=1;
                solve(row+1,n);
                board[row][col]=0;
            }
        }
    
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n;
    cin>>n;

    board.resize(n,vector<int>(n));
    solve(0,n);

    if(!found) cout<< -1;
    else{
        sort(ans.begin(),ans.end());
        for(int i=0;i<ans.size();i++){
            for(int j=0;j<n;j++){
                cout<<ans[i][j];
                if(j<n-1) cout<<" ";
            }cout<<"\n";
        }
    }
    
    return 0;
}
