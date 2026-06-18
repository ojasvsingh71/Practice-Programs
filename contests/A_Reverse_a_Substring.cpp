#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    // int t;
    // cin>>t;
    // while(t--){
        int n;
        cin>>n;
        string s;
        cin>>s;
        string temp=s;
        sort(temp.begin(),temp.end());

        if(temp==s){
            cout<<"NO\n";
        }else{
            cout<<"YES\n";

            // map<char,int> freq;
            // for(char c:s) temp[c]++;
            // temp="";

            // for(auto i:freq){
            //     for(int j=0;j<i.second;j++) temp.push_back(i.first);
            // }

            for(int i=0;i<n;i++){
                if(temp[i]!=s[i]){
                    cout<<i+1<<" ";
                    int j=i;
                    while(s[j]!=temp[i]) j++;
                    cout<<j+1<<"\n";
                    break;
                }
            }
        }

    // }
    
    return 0;
}
