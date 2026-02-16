#include<bits/stdc++.h>
using namespace std;

bool possible(long long f,int n,int k,long long w,vector<long long>& a,vector<long long>& b){
    int safe=n-k;
    vector<long long> dam;
    
    for(int i=0;i<n;i++){
        __int128 temp=(__int128)a[i]*(__int128)f-b[i];
        long long d;
        if(temp<=0) d=0;
        else if(temp>w) d=w+1;
        else d=(long long)(temp);
        dam.push_back(d);
    }
    sort(dam.begin(),dam.end());

    __int128 sum=0;
    for(int i=0;i<safe;i++){
        sum+=dam[i];
        if(sum>w) return false;
    }
    return sum<=(__int128)w;
}

int main(){
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int t;
    cin>>t;
    while(t--){
        int n,k;
        long long w;
        cin>>n>>k>>w;

        vector<long long> a(n);
        vector<long long> b(n);

        for(int i=0;i<n;i++) cin>>a[i];
        for(int i=0;i<n;i++) cin>>b[i];

        long long ans=0,low=0,high=4e18;

        while(low<=high){
            long long mid=low+(high-low)/2;

            if(possible(mid,n,k,w,a,b)){
                ans=mid;
                low=mid+1;
            }
            else high=mid-1;
        }

        cout<<ans<<"\n";
    }
    
}