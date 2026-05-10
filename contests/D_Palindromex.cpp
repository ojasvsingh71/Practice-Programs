#include <bits/stdc++.h>
using namespace std;

void out(int ls,int rs,vector<int>& m,int n,vector<int>& nums){
    while(ls>=0 && rs<2*n){
        if(nums[ls]!=nums[rs]){
            break;
        }
        m[nums[ls]]=1;
        ls--,rs++;
    }
}

void in(int ls,int rs,vector<int>& m,int n,vector<int>& nums,int& alert){
    while(ls<=rs){
        if(nums[ls]!=nums[rs]){
            alert=1;
            break;
        }
        m[nums[ls]]=1;
        ls++,rs--;
    }
}

void clean(vector<int>& m){
    for(int i=0;i<m.size();i++) m[i]=0;
}

int mex(vector<int>& m){
    for(int i=0;i<m.size();i++){
        if(m[i]==0){
            return i;
        }
    }return -1;
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n;
        cin>>n;
        vector<int> nums(2*n);
        for(int i=0;i<2*n;i++){
            cin>>nums[i];
        }
        
        int l=0,r=2*n-1;
        while(l<2*n && nums[l]!=0) l++;
        while(r>=0 && nums[r]!=0) r--;

        int alert=0;
        vector<int> m(n+1,0);
        in(l,r,m,n,nums,alert);
        out(l,r,m,n,nums);
        int mex1=mex(m);
        if(alert) {
            alert=0;
            mex1=1;
        }

        clean(m);
        // for(int i:m) cout<<i<<" ";
        // cout<<"\n";

        out(l,l,m,n,nums);
        int mex2=mex(m);
        clean(m);
        
        // for(int i:m) cout<<i<<" ";
        // cout<<"\n";

        out(r,r,m,n,nums);
        int mex3=mex(m);
        
        cout<<max(mex1,max(mex2,mex3))<<"\n";

    }
    
    return 0;
}
