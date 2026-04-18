#include<bits/stdc++.h>
using namespace std;

vector<vector<int>> board;

bool isSafe(int i,int j){
    int n=board.size();
    int dx[]={-1,-1,-1};
    int dy[]={-1,0,+1};
    int ii=i,jj=j;

    for(int l=0;l<3;l++){
        i=ii,j=jj;
        while(i>=0 && j>=0 && i<n && j<n){
            if(board[i][j]) return false;
            i+=dx[l],j+=dy[l];
        }
    }return true;
}

void Nqueens(int n,int level){
    if(level==n){
        cout<<"\n";
        for(int i=0;i<n;i++){
            for(int j=0;j<n;j++){
                if(board[i][j]){
                    cout<<"Q ";
                }else cout<<". ";
            }cout<<"\n";
        }cout<<"\n";
        return ;
    }

    for(int col=0;col<n;col++){
        if(isSafe(level,col)){
            board[level][col]=1;
            Nqueens(n,level+1);
            board[level][col]=0;
        }
    }
}

int main(){
    int n;
    cin>>n;

    board.resize(n,vector<int>(n,0));
    Nqueens(n,0);
}