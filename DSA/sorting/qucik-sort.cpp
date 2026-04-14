#include<iostream>
using namespace std;

int partition(int arr[],int low,int high){
    int pivot=arr[high];
    int i=low-1;

    for(int j=low;j<high;j++){
        if(arr[j]<pivot){
            i++;
            swap(arr[i],arr[j]);
        }
    }
    swap(arr[i+1],arr[high]);
    return i+1;
}

void quick_sort(int arr[],int low,int high){
    if(low<high){
        int mid=partition(arr,low,high);
        
        quick_sort(arr,low,mid-1);
        quick_sort(arr,mid+1,high);
    }
}

void display(int arr[],int n){
    for(int i=0;i<n;i++){
        printf("%d ",arr[i]);
    }printf("\n");
}

int main(){
    int n;
    cin>>n;

    int arr[n];
    for(int i=0;i<n;i++){
        cin>>arr[i];
    }
    display(arr,n);

    quick_sort(arr,0,n-1);

    display(arr,n);

    return 0;
}