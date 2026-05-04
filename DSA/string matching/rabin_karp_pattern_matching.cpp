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

    vector<int> textHash(n);
    vector<int> patternHash(m);

    int start=0;
    for(int i=0;i<m;i++){
        start+=(text[n-1-i]-'a')*pow(10,i);
    }
    textHash[n-m]=start;
    for(int i=n-m-1;i>=0;i--){
        textHash[i]=(textHash[i+1]-(text[i+m]-'a'))/10+(text[i]-'a')*pow(10,m-1);
    }start=0;
    for(int i=0;i<m;i++){
        start+=(pattern[m-1-i]-'a')*pow(10,i);
    }
    patternHash[0]=start;
    int found=0;
    vector<int> ans;
    for(int i=0;i<n;i++){
        if(textHash[i]==patternHash[0] && text.substr(i,m)==pattern) {
            found=1;
            ans.push_back(i);
        }
    }
    if(!found) cout<<"No Match";
    for(int i=0;i<ans.size();i++){
        cout<<ans[i];
        if(i<ans.size()-1) cout<<" ";
    }
    cout<<"\n";

    return 0;
}





// HELLO WORLD HELLO	
// HELLO