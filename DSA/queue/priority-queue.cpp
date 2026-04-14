#include<iostream>
using namespace std;

struct queue{
    int data;
    int priority;
    struct queue* next;
};
typedef struct queue* q;
q front=NULL,rear=NULL;

int isEmpty(){
    if(!front) return 1;
    return 0;
}

void enqueue(int x,int prio){
    q temp=(q)malloc(sizeof(struct queue));
    temp->data=x;
    temp->priority=prio;
    temp->next=NULL;
    if(!rear){
        front=rear=temp;
    }else{
        if(front->priority>prio){
            temp->next=front;
            front=temp;
            return ;
        }q last=front;
        while(last->next && last->next->priority<prio){
            last=last->next;
        }if(last->next!=NULL){
            temp->next=last->next;
            last->next=temp;
        }else{
            last->next=temp;
            rear=temp;
        }
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
        int choice,tar,prio;
        printf("1.Enqueue\n2.Dequeue\n3.Display\n4.Exit\nEnter your choice:");
        cin>>choice;
        if(choice==1){
            cout<<"\nEnter the element : ";
            cin>>tar;
            cout<<"\nEnter the priority : ";
            cin>>prio;
            enqueue(tar,prio);
        }else if(choice==2){
            dequeue();
        }else if(choice==3){
            display();
        }else if(choice==4){
            break;
        }else{
            printf("\nPlz enter a valid choice...\n");
        }
    }

    return 0;
}