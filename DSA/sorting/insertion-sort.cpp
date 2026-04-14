#include<iostream>
using namespace std;

void insertion_sort(int arr[],int n){
    int key,j;
    
    for(int i=1;i<n;i++){
        key=arr[i];
        j=i-1;

        while(j>=0 && arr[j]>key){
            arr[j+1]=arr[j];
            j--;
        }
        arr[j+1]=key;
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

    insertion_sort(arr,n);

    display(arr,n);

    return 0;
}