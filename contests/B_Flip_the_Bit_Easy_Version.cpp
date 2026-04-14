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

        int bu=0;
        for(int i=0;i<n;i++){
            if(nums[i]!=nums[p-1]) {
                bu=1;
                break;
            }
        }
        if(!bu){
            cout<<0<<"\n";
            continue;
        }

        // all one
        int ls = 0, rs = n - 1;
        if (nums[p-1] == 1)
        {
            
            int op1 = 0;
            while (ls < rs)
            {
                while (ls != p-1 && ((nums[ls] == 1 && op1 % 2 == 0) || (nums[ls] == 0 && op1 % 2 == 1)))
                    ls++;
                while (rs != p-1 && ((nums[rs] == 1 && op1 % 2 == 0) || (nums[rs] == 0 && op1 % 2 == 1)))
                    rs--;
                if (ls == rs)
                    break;
                op1++;
            }
            cout<<op1+1<<"\n";
        }
        else
        {
            // all zero
            int op2 = 0;
            ls = 0, rs = n - 1;
            while (ls < rs)
            {
                while (ls != p-1 && ((nums[ls] == 0 && op2 % 2 == 0) || (nums[ls] == 1 && op2 % 2 == 1)))
                    ls++;
                while (rs != p-1 && ((nums[rs] == 0 && op2 % 2 == 0) || (nums[rs] == 1 && op2 % 2 == 1)))
                    rs--;
                if (ls == rs)
                    break;
                op2++;
            }
            cout<<op2+1<<"\n";
        }
        
    }
}