#include<iostream>
using namespace std;

#define MAX 1000
int stack[MAX];
int top=-1;

int isEmpty(){
    if(top==-1) return 1;
    return 0;
}

void push(int x){
    if(top==MAX-1){
        printf("\nStack overflow!!!\n");
    }else{
        stack[++top]=x;
    }
}

int pop(){
    if(isEmpty()){
        printf("\nStack underflow!!!\n");
        return -1;
    }return stack[top--];
}

int peek(){
    if(isEmpty()){
        printf("\nStack underflow!!!\n");
        return -1;
    }return stack[top];
}

void display(){
    if(isEmpty()){
        printf("\nStack underflow\n");
    }else{
        printf("Elements in the stack are : ");
        for(int i=top;i>=0;i--){
            printf("%d ",stack[i]);
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