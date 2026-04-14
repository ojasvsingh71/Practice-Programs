#include<iostream>
using namespace std;

struct dequeue{
    int val;
    struct dequeue* next;
};
typedef struct dequeue* dq;

dq front=NULL,rear=NULL;

int isEmpty(){
    if(!front) return 1;
    return 0;
}

void push(int x){
    dq temp=(dq)malloc(sizeof(struct dequeue));
    temp->val=x;
    temp->next=front;
    if(!rear){
       rear=front=temp; 
    }else{
        temp->next=front;
        front=temp;
    }
}

void pop(){
    if(isEmpty()){
        printf("\nQueue is Full\n");
        return ;
    }printf("\n%d popped\n",front->val);
    if(front==rear){
        front=rear=NULL;
    }else{
        front=front->next;
    }
}

void inject(int x){
    dq temp=(dq)malloc(sizeof(struct dequeue));
    temp->val=x;
    temp->next=NULL;
    if(!front){
       front=rear=temp; 
    }else{
        rear->next=temp;
        rear=temp;
    }
}

void eject(){
    if(isEmpty()){
        printf("\nQeueue is empty\n");
        return ;
    }printf("\nEjecting %d\n",rear->val);
    if(front==rear){
        front=rear=NULL;
    }else{
        dq temp=front;
        while(temp->next!=rear){
            temp=temp->next;
        }temp->next=NULL;
        rear=temp;
    }
}

void display(){
    if(isEmpty()){
        printf("\nQueue is empty!!\n");
        return ;
    }dq temp=front;
    printf("\nElements in Queue : ");
    while(temp){
        printf("%d ",temp->val);
        temp=temp->next;
    }printf("\n");
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