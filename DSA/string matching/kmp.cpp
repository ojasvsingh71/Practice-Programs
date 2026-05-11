#include <bits/stdc++.h>
using namespace std;

vector<int> buildlps(string pattern){
    int m=pattern.size();

    vector<int> lps(m,0);
    int i=1;
    int len=0;
    while(i<m){
        if(pattern[i]==pattern[len]){
            len++;
            lps[i]=len;
            i++;
        }else{
            if(len==0){
                lps[i]=0;
                i++;
            }else{
                len=lps[len-1];
            }
        }
    }
    return lps;
}

int kmp(string text,string pattern){
    vector<int> lps=buildlps(pattern);

    int n=text.size();
    int m=pattern.size();
    int ans=-1;
    int i=0,j=0;
    while(i<n){
        if(text[i]==pattern[j]){
            i++;
            j++;
        }
        if(j==m){
            ans=i-j;
            break;
        }
        else if(i<n && text[i]!=pattern[j]){
            if(j==0) i++;
            else j=lps[j-1];
        }   
    }
    return ans;
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    string text,pattern;
    cin>>text>>pattern;

    cout<<kmp(text,pattern);
    
    return 0;
}



// abracadabracad	
// cad	