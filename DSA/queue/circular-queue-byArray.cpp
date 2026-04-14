#include<iostream>
using namespace std;

#define MAX 5

int cqueue[MAX];
int front=-1,rear=-1;

int isEmpty(){
    if(front==-1) return 1;
    return 0;
}

int isFull(){
    if((rear+1)%MAX==front) return 1;
    return 0;
}

void enqueue(int x){
    if(isFull()){
        printf("\nQueue is Full\n");
        return ;
    }if(front==-1 && rear==-1){
        front=rear=0;
    }else{
        rear=(rear+1)%MAX;
    }
    cqueue[rear]=x;
}

void dequeue(){
    if(isEmpty()){
        printf("\nQueue is empty!!\n");
        return ;
    }printf("\nDequeued %d\n",cqueue[front]);
    if(front==rear){
        front=rear=-1;
    }else{
        front=(front+1)%MAX;
    }
}

void display(){
    if(isEmpty()){
        printf("\nQueue is empty\n");
        return;
    }printf("\nElements of queue are : ");
    if(front<rear){
        for(int i=front;i<=rear;i++){
            printf("%d ",cqueue[i]);
        }printf("\n");
    }else{
        for(int i=front;i<MAX;i++){
            printf("%d ",cqueue[i]);
        }for(int i=0;i<=rear;i++){
            printf("%d ",cqueue[i]);
        }printf("\n");
    }
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