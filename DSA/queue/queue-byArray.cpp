#include<iostream>
using namespace std;

#define MAX 100

int queue[MAX];
int front=-1;
int rear=-1;

int isEmpty(){
    if(front==-1) return 1;
    return 0;
}

int isFull(){
    if(rear==MAX-1) return 1;
    return 0;
}

void enqueue(int x){
    if(isFull()){
        printf("\nQueue is Full\n");
        return ;
    }else if(front==-1){
        front++;
    }queue[++rear]=x;
}

void dequeue(){
    if(isEmpty()){
        printf("\nQeue is empty\n");
        return ;
    }
    printf("\n%d dequeued\n",queue[front]);
    if(front==rear){
        front=rear=-1;
    }else{
        front++;
    }
}

void display(){
    if(isEmpty()){
        printf("\nQueue is empty\n");
    }else{
        printf("\nElements in queue are : ");
        for(int i=front;i<=rear;i++){
            printf("%d ",queue[i]);
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