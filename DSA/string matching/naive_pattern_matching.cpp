#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    string pattern,text;
    getline(cin,text);
    getline(cin,pattern);

    int found=0;
    // cout<<text<<" \n"<<pattern;
    int n=text.size();
    int m=pattern.size();
    for(int i=0;i<n-m+1;i++){
        int j=0;
        for(j=0;j<m;j++){
            if(text[i+j]!=pattern[j]) break;
        }
        if(j==m){
            found=1;
            cout<<i<<" ";
        }
    }

    if(!found){
        cout<<"No Match\n";
    }

    return 0;
}





// ABABDABACDABABCABAB	
// ABABCABAB