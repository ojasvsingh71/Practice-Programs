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

void push(int x){
    if(isFull() || front==0){
        printf("\nQueue is Full\n");
        return ;
    }queue[--front]=x;
}

void pop(){
    if(isEmpty()){
        printf("\nQueue is Full\n");
        return ;
    }printf("\n%d popped\n",queue[front]);
    if(front==rear){
        front=rear=-1;
    }else{
        front++;
    }
}

void inject(int x){
    if(isFull()){
        printf("\nQueue is Full\n");
        return ;
    }queue[++rear]=x;
    if(front=-1){
        front++;
    }
}

void eject(){
    if(isEmpty()){
        printf("\nQeueue is empty\n");
        return ;
    }
    printf("\n%d ejected\n",queue[rear]);
    if(front==rear){
        front=rear=-1;
    }else{
        rear--;
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
        printf("1.Push\n2.Pop\n3.Inject\n4.Eject\n5.Display\n6.Exit\nEnter your choice:");
        cin>>choice;
        if(choice==1){
            cout<<"\nEnter the element : ";
            cin>>tar;
            push(tar);
        }else if(choice==2){
            pop();
        }else if(choice==3){
            cout<<"\nEnter the element : ";
            cin>>tar;
            inject(tar);
        }else if(choice==4){
            eject();
        }else if(choice==5){
            display();
        }else if(choice==6){
            break;
        }else{
            printf("Plz enter a valid choice...");
        }
    }

    return 0;
}