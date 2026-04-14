#include<iostream>
#include<stdlib.h>
#include<stdio.h>
using namespace std;

#define true 1
#define false 0

struct node{
    int data;
    struct node* right;
    struct node* left;
    int leftThread;
    int rightThread;
};
typedef struct node* bu;

bu root=NULL;

void insert(int data){
    bu temp=root;
    while(1){
        if(data>temp->data){
            if(temp->rightThread==true){
                break;
            }temp=temp->right;
        }else if(data<temp->data){
            if(temp->leftThread==true){
                break;
            }temp=temp->left;
        }else{
            cout<<"Duplicate nodes not allowed\n";
            return ;
        }
    }
    bu tempu=(bu)malloc(sizeof(struct node));
    tempu->data=data;
    tempu->leftThread=tempu->rightThread=1;
    if(data>temp->data){
        tempu->right=temp->right;
        tempu->left=temp;
        temp->right=tempu;
        temp->rightThread=false;
    }else{
        tempu->left=temp->left;
        tempu->right=temp;
        temp->left=tempu;
        temp->leftThread=false;
    }
}

void display(){
    bu p=root;
    bu temp;
    while(1){
        temp=p;
        p=p->right;
        if(temp->rightThread==false){
            while(p->leftThread==false){
                p=p->left;
            }
        }if(p==root){
            break;
        }
        printf("%d ",p->data);

    }printf("\n");
}


int main(){
    root=(bu)malloc(sizeof(struct node));
    root->data=INT16_MAX;
    root->rightThread=0;
    root->right=root->left=root;
    root->leftThread=true;

    insert(10);
    insert(11);
    insert(19);
    insert(30);
    insert(25);

    display();

    return 0;
}