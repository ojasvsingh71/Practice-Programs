#include<iostream>
using namespace std;

void selection_sort_Min(int arr[],int n){
    for(int i=0;i<n;i++){
        int min_index=i;

        for(int j=i+1;j<n;j++){
            if(arr[j]<arr[min_index]){
                min_index=j;
            }
        }

        if(min_index!=i){
            swap(arr[i],arr[min_index]);
        }
    }
}

void selection_sort_Max(int arr[],int n){
    for(int i=n-1;i>=0;i--){
        int max_index=i;

        for(int j=i-1;j>=0;j--){
            if(arr[j]>arr[max_index]){
                max_index=j;
            }
        }

        if(max_index!=i){
            swap(arr[i],arr[max_index]);
        }
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

    selection_sort_Max(arr,n);
    selection_sort_Min(arr,n);

    display(arr,n);

    return 0;
}