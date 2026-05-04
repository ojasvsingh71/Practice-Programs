#include <bits/stdc++.h>
using namespace std;

int main()
{
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int t;
    cin >> t;

    while (t--)
    {
        int n, k;
        cin >> n >> k;
        vector<int> nums(n);
        for (int i = 0; i < n; i++)
            cin >> nums[i];
        int p;
        cin >> p;
        p--;

        int tar=nums[p];

        int cost=0;
        int ls=0,rs=n-1;
        while(ls<p && nums[ls]==tar) ls++;
        while(rs>p && nums[rs]==tar) rs--;
        // cout<<ls<<" -- "<<rs<<"\n";
        while(ls!=rs){
            cost++;
            // cout<<ls<<" -- "<<rs<<"\n";
            nums[p]=1-nums[p];
            while(ls<p && nums[ls]==nums[p]) ls++;
            while(rs>p && nums[rs]==nums[p]) rs--;
        }
        if(cost%2==1) cost++;
        cout<<cost<<"\n";
        
        // cout<<"\n";
    }
}