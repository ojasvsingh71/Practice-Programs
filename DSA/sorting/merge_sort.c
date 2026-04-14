#include <stdio.h>

void merge(int arr[], int low, int high, int mid)
{
    int n1 = mid - low + 1;
    int n2 = high - mid;

    int l[n1], r[n2];

    for (int i = 0; i < n1; i++)
    {
        l[i] = arr[low + i];
    }
    for (int i = 0; i < n2; i++)
    {
        r[i] = arr[mid + 1 + i];
    }

    int i = 0, j = 0, k = low;

    while (i < n1 && j < n2)
    {
        if (l[i] < r[j])
        {
            arr[k++] = l[i++];
        }
        else
        {
            arr[k++] = r[j++];
        }
    }
    while (i < n1)
    {
        arr[k++] = l[i++];
    }
    while (j < n2)
    {
        arr[k++] = r[j++];
    }
}

void mergeSort(int arr[], int low, int high)
{
    if (low < high)
    {
        int mid = low + (high - low) / 2;

        mergeSort(arr, low, mid);
        mergeSort(arr, mid + 1, high);

        merge(arr, low, high, mid);
    }
}

struct node{
    int data;
    struct node* next;
};
typedef struct node * NODE;

NODE get_middle(NODE first){
    NODE fast=first->next;
    NODE slow=first;

    while(fast && fast->next){
        fast=fast->next->next;
        slow=slow->next;
    }

    return slow;
}


int main()
{
    int num;
    scanf("%d", &num);
    int arr[num];
    for (int i = 0; i < num; i++)
    {
        scanf("%d", &arr[i]);
    }
    mergeSort(arr, 0, num - 1);
    printf("Sorted array : ");
    for (int i = 0; i < num; i++)
    {
        printf("%d ", arr[i]);
    }
    printf("\n");
}