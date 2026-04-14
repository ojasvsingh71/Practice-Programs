#include<iostream>
using namespace std;

void bubble_sort(int arr[],int n){
    for(int i=0;i<n;i++){
        int swapped=0;
        for(int j=0;j<n-i-1;j++){
            if(arr[j]>arr[j+1]){
                swap(arr[j],arr[j+1]);
                swapped=1;
            }
        }if(!swapped) break;
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

    bubble_sort(arr,n);

    display(arr,n);

    return 0;
}