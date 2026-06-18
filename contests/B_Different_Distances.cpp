#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n;
        cin>>n;

        // vector<int> last(n);
        // vector<int> freq(n,4);


        for(int i=0;i<2*n;i++) {
            cout<<i%n+1<<" ";
            // freq[i%n+1]--;
            // last[i%n+1]=n-1;
        }
        
        cout<<n<<" ";
        for(int i=0;i<n-1;i++){
            cout<<i+1<<" ";
        }
        for(int i=0;i<n;i++){
            cout<<i+1<<" ";
        }
        cout<<"\n";
    }
    
    return 0;
}
