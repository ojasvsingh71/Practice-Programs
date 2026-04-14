#include<bits/stdc++.h>
using namespace std;

int partition(vector<int>& nums,int low,int high){
    int pivot=nums[low],i=low+1,j=high;
    while(i<=j){
        while(i<=high && nums[i]<=pivot) i++;
        while(j>=low && nums[j]>pivot) j--;
        if(i<j) swap(nums[i],nums[j]);
    }swap(nums[low],nums[j]);
    return j;
}

void quick_sort(vector<int>& nums,int low,int high){
    if(low<high){
        int par=partition(nums,low,high);
        quick_sort(nums,low,par-1);
        quick_sort(nums,par+1,high);
    }
}

void display(vector<int>& arr,int n){
    for(int i:arr){
        cout<<i<<" ";
    }cout<<"\n";
}

int main(){
    int n;
    cin>>n;

    vector<int> arr(n);
    for(int i=0;i<n;i++){
        cin>>arr[i];
    }
    display(arr,n);

    quick_sort(arr,0,n-1);

    display(arr,n);

    return 0;
}