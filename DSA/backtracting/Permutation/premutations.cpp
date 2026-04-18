#include<bits/stdc++.h>
using namespace std;

void perm(int i,string& s){
    if(i==s.size()){
        cout<<s<<"\n";
        return ;
    }
    for(int j=i;j<s.size();j++){
        swap(s[i],s[j]);
        perm(i+1,s);
        swap(s[i],s[j]);
    }
}

void lexo_perm(int i,string& s){
    if(i==s.size()){
        cout<<s<<"\n";
        return ;
    }
    for(int j=i;j<s.size();j++){
        char temp=s[j];
        for(int k=j;k>i;k--){
            s[k]=s[k-1];
        }s[i]=temp;
        
        lexo_perm(i+1,s);

        temp=s[i];
        for(int k=i;k<j;k++){
            s[k]=s[k+1];
        }s[j]=temp;
    }
}

int main(){
    string s;
    cin>>s;

    cout<<"\nNon lexicographically Permutation :-\n";
    perm(0,s);
    
    sort(s.begin(),s.end());
    cout<<"\nLexicographically Permutation :-\n";
    lexo_perm(0,s);
}
