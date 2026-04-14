#include<iostream>
using namespace std;

struct queue{
    int data;
    struct queue* next;
};
typedef struct queue* q;
q front=NULL,rear=NULL;

int isEmpty(){
    if(!front) return 1;
    return 0;
}

void enqueue(int x){
    q temp=(q)malloc(sizeof(struct queue));
    temp->data=x;
    temp->next=NULL;
    if(!rear){
        front=rear=temp;
    }else{
        rear->next=temp;
        rear=temp;
    }
}

void dequeue(){
    if(isEmpty()){
        printf("\nQueue is empty!!\n");
        return ;
    }printf("\nDequeued %d\n",front->data);
    if(front==rear){
        front=rear=NULL;
    }else{
        front=front->next;
    }
}

void display(){
    if(isEmpty()){
        printf("\nQueue is empty!!\n");
        return ;
    }q temp=front;
    printf("\nElements in Queue : ");
    while(temp){
        printf("%d ",temp->data);
        temp=temp->next;
    }printf("\n");
}

int main(){
    while(true){
        int choice,tar;
        printf("1.Enqueue\n2.Dequeue\n3.Display\n4.Exit\nEnter your choice:");
        cin>>choice;
        if(choice==1){
            cout<<"\nEnter the element : ";
            cin>>tar;
            enqueue(tar);
        }else if(choice==2){
            dequeue();
        }else if(choice==3){
            display();
        }else if(choice==4){
            break;
        }else{
            printf("Plz enter a valid choice...");
        }
    }

    return 0;
}