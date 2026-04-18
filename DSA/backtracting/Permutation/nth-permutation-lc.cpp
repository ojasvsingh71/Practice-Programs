#include<bits/stdc++.h>
using namespace std;

int cnt=0;
string result="";

void prem(string& ans,int k,int i){
    if(i==ans.size()){
        cnt++;
        if(cnt==k) {
            result=ans;
        }
        return ;
    }

    for(int j=i;j<ans.size();j++){
        char temp=ans[j];
        for(int l=j;l>i;l--){
            ans[l]=ans[l-1];
        }ans[i]=temp;

        prem(ans,k,i+1);
        if(result!="") return ;

        temp=ans[i];
        for(int l=i;l<j;l++){
            ans[l]=ans[l+1];
        }ans[j]=temp;
    }
}

string getPermutation(int n, int k) {
    string ans;
    for(int i=1;i<=n;i++){
        ans+=('0'+i);
    }
    prem(ans,k,0);
    return result;
}

int main(){
    int n,k;
    cin>>n>>k;

    cout<<getPermutation(n,k);
}