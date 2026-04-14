#include<iostream>
#include<vector>
using namespace std;

int nCr(int N,int R){
    vector<vector<int>> C(N + 1, vector<int>(R + 1, 0));
    for(int n=0;n<=N;n++){
        for(int r=0;r<=min(n,R);r++){
            if(r==1 || r==n){
                C[n][r]=1;
            }else {
                C[n][r]=C[n-1][r-1]+C[n-1][r];
            }
        }
    }return C[N][R];
}

int main(){
    int n,r;
    cin>>n>>r;

    printf("nCr : %d\n",nCr(n,r));

    return 0;
}