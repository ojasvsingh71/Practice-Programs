#include <bits/stdc++.h>
using namespace std;



void expand(vector<int>& nums,int val,int i,int &alert){
    // int ls=i-1,rs=i+1;
    int n=(int)nums.size();
    // val--;

    // while(ls>=0 || rs<n){
    //     if(val==-1) break;
    //     if(ls>=0) {
    //         if(nums[ls]==-1) nums[ls]=val;
    //         else if(nums[ls]!=val) {
    //             // cout<<ls<<"-- ";
    //             alert=1;
    //             break;
    //         }
    //     }
    //     if(rs<n) {
    //         if(nums[rs]==-1) nums[rs]=val;
    //         else if(nums[rs]!=val){
    //             // cout<<rs<<"-- ";
    //             alert=1;
    //             break;
    //         }
    //     }
    //     ls--;
    //     rs++;
    //     val--;
    // }

    int ls=i-val;
    int rs=i+val;
    int bu=0;

    if(ls>=0){
        if(nums[ls]==-1){
            nums[ls]=0;
            bu=1;
        }else if(nums[ls]!=0) alert=1;
    }

    if(rs<n && !bu){
        if(nums[rs]==-1){
            nums[rs]=0;
        }else if(nums[rs]!=0) alert=1;
    }
    if(alert){
        cout<<ls<<" "<<rs<<"---\n";
    }
}

int main() {
    ios_base::sync_with_stdio(false);
    cin.tie(NULL);
    
    int t;
    cin>>t;
    while(t--){
        int n;
        cin>>n;
        vector<int> nums(n);

        int maxi=0;
        vector<int> index;

        priority_queue<pair<int,int>> m;

        for(int i=0;i<n;i++){
            cin>>nums[i];
            // if(nums[i]>maxi){
            //     index.clear();
            //     maxi=nums[i];
            //     index.push_back(i);
            // }else if(nums[i]==maxi){
            //     index.push_back(i);
            // }
            if(nums[i]!=-1 && nums[i]!=0) m.push({nums[i],i});
        }
        int alert=0;
        // cout<<alert<<"-------";
        // for(int i:index){
        //     expand(nums,maxi,i,alert);
        //     if(alert==1) break;
        // }
        while(!m.empty()){
            auto curr=m.top();
            m.pop();
            cout<<curr.first<<"<<---";
            expand(nums,curr.first,curr.second,alert);
            if(alert==1) break;
        }
        

        if(alert==1){
            cout<<-1<<"\n";
        }else{
            if(index.size()==0){
                if(nums[0]==0){
                    continue;
                }else{
                    for(int i=0;i<n;i++){
                        nums[i]=i;
                    }
                }
            }
            for(int i:nums){
                if(i!=0) cout<<0;
                else cout<<1;
            }
            cout<<"\n";
        }

    }
    
    return 0;
}
