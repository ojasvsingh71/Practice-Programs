#include <bits/stdc++.h>
using namespace std;

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int n;
    cin>>n;
    vector<vector<int>> nums(n,vector<int>(n));
    for(int i=0;i<n;i++){
        for(int j=0;j<n;j++){
            cin>>nums[i][j];cn.;
        }
    }
    vector<int> cities;
    for(int i=0;i<n;i++) cities.push_back(i);

    vector<int> res=cities;

    int ans=INT_MAX;
    do{
        int currentCost=0;
        int k=0;
        for(int i:cities){
            currentCost+=nums[k][i];
            k=i;
        }
        currentCost+=nums[k][0];

        if(currentCost<ans){
            ans=currentCost;
            res=cities;
        }
    }while(next_permutation(cities.begin(),cities.end()));

    cout<<ans<<"\n";
    for(int i:res) cout<<i<<" ";
    cout<<res[0]<<" \n";

    return 0;
}




// 5	
// 0 20 30 10 11	
// 15 0 16 4 2	
// 10 3 0 15 4	
// 7 14 8 0 5	
// 2 4 6 8 0