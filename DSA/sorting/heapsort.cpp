#include<iostream>
#include<vector>
using namespace std;

void display(vector<int> arr,int n){
    for(int i=0;i<n;i++){
        printf("%d ",arr[i]);
    }printf("\n");
}

void heapify(vector<int>& arr,int n,int i){
    int largest=i;
    int l=2*i+1;
    int r=2*i+2;

    if(l<n && arr[largest]<arr[l]) largest=l;
    if(r<n && arr[largest]<arr[r]) largest=r;

    if(largest!=i){
        swap(arr[largest],arr[i]);

        heapify(arr,n,largest);
    }
}

void heapsort(vector<int>& arr,int n){
    for(int i=n/2-1;i>=0;i--){
        heapify(arr,n,i);
    }

    for(int i=n-1;i>=0;i--){
        swap(arr[i],arr[0]);

        heapify(arr,i,0);
    }
}

int main(){
    cout<<"Enter the array length"<<endl;
    int num;
    cin>>num;
    vector<int> arr;
    for(int i=0;i<num;i++){
        int data;
        cin>>data;
        arr.push_back(data);
    }
    printf("Current array\n");
    display(arr,num);

    printf("Sorted array\n");
    heapsort(arr,num);
    display(arr,num);
}