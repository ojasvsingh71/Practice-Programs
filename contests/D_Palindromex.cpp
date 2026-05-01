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
        vector<int> nums(2*n);
        for(int i=0;i<2*n;i++){
            cin>>nums[i];
        }
        int l=0,r=2*n-1;
        while(l<2*n && nums[l]!=0) l++;
        while(r>=0 && nums[r]!=0) r--;
        cout<<"L ="<<l<<"R ="<<r<<"\n";
        int mex=1;
        if(l==0 || r==2*n-1){
            int bu=0;
            vector<int> track(n,0);
            track[0]=1;
            while(l<=r){
                if(nums[l]!=nums[r]){
                    bu=1;
                    cout<<l<<"++++\n";
                    
                    break;
                }track[nums[l]]=1;
                l++,r--;
            }
            if(bu) mex=1;
            else{
                for(int i=0;i<n;i++){
                    if(track[i]==0){
                        mex=i;
                        break;
                    }
                }
            }
        }else{
            vector<int> track(n,0);
            track[0]=1;
            int hu=0;
            int ll=l,rr=r;
            while(l>=0 && r<2*n){
                if(nums[l]!=nums[r]){
                    hu=1;
                    cout<<l<<"++++\n";
                    break;
                }track[nums[l]]=1;
                l--,r++;
            }

            if(hu){
                for(int i=1;i<n;i++){
                    track[i]=0;
                }
            }
            l=ll,r=rr;

            int bu=0;
            while(l<=r){
                if(nums[l]!=nums[r]){
                    bu=1;
                    cout<<l<<"++++\n";
                    break;
                }track[nums[l]]=1;
                l++,r--;
            }
            if(bu) mex=1;
            else{
                for(int i=0;i<n;i++){
                    if(track[i]==0){
                        mex=max(mex,i);
                        break;
                    }
                }
            }
        }
        cout<<mex<<"\n";

    }
    
    return 0;
}
