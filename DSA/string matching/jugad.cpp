#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    string text,pattern;
    cin>>text>>pattern;

    if(text.find(pattern)!=string::npos){
        cout<<text.find(pattern)<<"\n";
    }else cout<<"Not Found\n";
    
    return 0;
}
