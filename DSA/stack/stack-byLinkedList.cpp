#include<iostream>
using namespace std;

struct stack{
    int val;
    struct stack* next;
};
typedef struct stack* stk;

stk top=NULL;

int isEmpty(){
    if(!top) return 1;
    return 0;
}

void push(int x){
    stk temp=(stk)malloc(sizeof(struct stack));
    temp->val=x;
    temp->next=top;
    top=temp;
}

int pop(){
    if(isEmpty()){
        printf("\nStack is empty!!!\n");
        return -1;
    }
    stk temp=top;
    top=top->next;
    return temp->val;
}

int peek(){
    if(isEmpty()){
        printf("\nStack is empty\n");
        return -1;
    }return top->val;
}

void display(){
    if(isEmpty()){
        printf("\nStack is empty\n");
    }else{
        stk temp=top;
        while(temp){
            printf("%d ",temp->val);
            temp=temp->next;
        }printf("\n");
    }
}

int main(){
    while(true){
        int choice,tar;
        printf("1.Push\n2.Pop\n3.Peek\n4.Display\n5.Exit\nEnter your choice:");
        cin>>choice;
        if(choice==1){
            cout<<"\nEnter the element : ";
            cin>>tar;
            push(tar);
        }else if(choice==2){
            printf("\nPopped %d\n",pop());
        }else if(choice==3){
            printf("\nTop element : %d\n",peek());
        }else if(choice==4){
            display();
        }else if(choice==5){
            break;
        }else{
            printf("Plz enter a valid choice...");
        }
    }

    return 0;
}