#include <bits/stdc++.h>
using namespace std;

vector<int> primes(1e6+1,1);

void seive(){
    for(int i=2;i*i<=1e6;i++){
        if(primes[i]){
            for(int j=i*i;j<=1e6;j+=i){
                primes[j]=0;
            }
        }
    }
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    seive();
    primes[1]=0;
    
    int t;
    cin>>t;
    while(t--){
        int n;
        cin>>n;
        long long nums;
        cin>>nums;
        string s=to_string(nums);

        int bu=0;
        string ans;
        for(int i=0;i<n;i++){
            string curr;
            for(int j=i;j<n && j<i+6;j++){
                curr+=s[j];
                try{
                    int hu=stol(curr);
                }catch(exception e){
                    cout<<curr<<"\n";
                }
                // if(!primes[stol(curr)]){
                //     ans=min(ans,curr);
                // }
            }
        }
        // cout<<ans.size()<<"\n"<<ans<<"\n";

    }
    
    return 0;
}
