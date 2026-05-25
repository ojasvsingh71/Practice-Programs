#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    string text,pattern;
    getline(cin,text);
    getline(cin,pattern);

    int n=text.size();
    int m=pattern.size();

    bool found=false;
    for(int i=0;i<m-n+1;i++){
        bool no=false;
        for(int j=0;j<m;j++){
            if(text[i+j]!=pattern[j]){
                no=true;
                break;
            }
        }if(!no) {
            found=true;
            break;
        }
    }


    
    return 0;
}
