#include<iostream>
using namespace std;

struct cqueue{
    int val;
    struct cqueue* next;
};
typedef struct cqueue* cq;

cq front=NULL,rear=NULL;

int isEmpty(){
    if(!front) return 1;
    return 0;
}

void enqueue(int x){
    cq temp=(cq)malloc(sizeof(struct cqueue));
    temp->val=x;
    temp->next=NULL;
    if(!rear){
        front=rear=temp;
        rear->next=front;
    }else{
        rear->next=temp;
        temp->next=front;
        rear=temp;
    }
}

void dequeue(){
    if(isEmpty()){
        printf("\nQueue is empty!!\n");
        return ;
    }printf("\nDequeued %d\n",front->val);
    if(front==rear){
        front=rear=NULL;
    }else{
        rear->next=front->next;
        front=front->next;
    }
}

void display(){
    if(isEmpty()){
        printf("\nQueue is empty!!\n");
        return ;
    }printf("Elements of Queue are : ");
    cq temp=front;
    do{
        printf("%d ",temp->val);
        temp=temp->next;
    }while(temp!=front);
    printf("\n");
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