#include<iostream>
using namespace std;

struct Node{
    int val;
    struct Node* next;

    Node():val(0),next(nullptr){}
    Node(int x):val(x),next(nullptr){}
};

Node* add(Node* first,int x){
    if(!first) {
        first=new Node(x);
        return first;
    }Node* temp=new Node(x);
    Node* last=first;
    while(last->next){
        last=last->next;
    }last->next=temp;
    return first;
}

void display(Node* first){
    if(!first){
        cout<<"Empty Linked List"<<endl;
        return ;
    }Node* last=first;
    while(last){
        cout<<last->val<<" -> ";
        last=last->next;
    }cout<<"NULL"<<endl;
}

Node* reverse(Node* first){
    Node* prev=NULL;
    while(first){
        Node* nexti=first->next;
        first->next=prev;
        prev=first;
        first=nexti;
    }return prev;
}

int main(){
    Node* bu=NULL;
    
    int num;
    cin>>num;
    while(num--){
        int data;
        cin>>data;
        bu=add(bu,data);
    }

    display(bu);
    bu=reverse(bu);
    display(bu);
    
    return 0;
}