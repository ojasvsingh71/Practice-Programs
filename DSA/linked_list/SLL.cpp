#include<iostream>
using namespace std;

struct Node{
    int val;
    struct Node* next;
};
typedef struct Node* bu;

bu newNode(int x){
    bu temp=(bu)malloc(sizeof(struct Node));
    temp->val=x;
    temp->next=NULL;
    return temp;
}

int count(bu first){
    int bu=0;
    while(first){
        bu++;
        first=first->next;
    }return bu;
}

int isEmpty(bu first){
    if(!first) return 1;
    return 0;
}

bu AddAtStart(bu first,int x){
    if(!first) return newNode(x);
    bu temp=newNode(x);
    temp->next=first;
    return temp;
}

bu AddAtEnd(bu first,int x){
    if(!first) return newNode(x);
    bu temp=newNode(x);
    bu last=first;
    while(last->next){
        last=last->next;
    }last->next=temp;
    return first;
}


bu AddInBetween(bu first,int x,int pos){
    if(pos<1 || pos>count(first)+1){
        cout<<"\nKindly enter a valid postion!!!\n";
        return first;
    }if(isEmpty(first)){
        cout<<"\nLinked list is empty!!!\n";
        return first;
    }bu temp=newNode(x);
    bu last=first;
    if(pos==1){
        temp->next=first;
        return temp;
    }for(int i=1;i<pos-1;i++){
        last=last->next;
    }temp->next=last->next;
    last->next=temp;
    return first;
}

bu DeletionByElement(bu first,int x){
    if(isEmpty(first)){
        cout<<"\nLinked List is empty\n";
        return first;
    }if(first->val==x){
        bu temp=first;
        first=first->next;
        free(temp);
        return first;
    }bu prev=first,last=first;
    while(last){
        if(last->val==x){
            prev->next=last->next;
            free(last);
            return first;
        }prev=last;
        last=last->next;
    }cout<<"\nElement not found!!!\n";
    return first;
}

bu DeletionByPosition(bu first,int pos){
    if(isEmpty(first)){
        cout<<"\nLinked List is empty!!!\n";
        return first;
    }if(pos<1 || pos>count(first)){
        cout<<"\nKindly enter a valid position!!!\n";
        return first;
    }if(pos==1){
        first=first->next;
        return first;
    }bu last=first;
    bu prev=first;
    for(int i=1;i<pos;i++){
        prev=last;
        last=last->next;
    }prev->next=last->next;
    free(last);
    return first;
}

void display(bu first){
    if(isEmpty(first)){
        cout<<"\nLinked List is empty!!!\n";
        return ;
    }
    while(first){
        cout<<first->val<<" -> ";
        first=first->next;
    }cout<<"NULL\n";
}

int main(){
    bu forward=NULL;
    bu backward=NULL;
    int num,pos,tar;

    cout<<"\nEnter number of nodes to be inserted : \n";
    cin>>num;

    cout<<"\nEnter the elements : \n";
    while(num--){
        int data;
        cin>>data;
        forward=AddAtEnd(forward,data);
        backward=AddAtStart(backward,data);
    }

    cout<<"\nLinked list in forward direction : ";
    display(forward);

    cout<<"\nLinked list in backward direction : ";
    display(backward);

    cout<<"\nEnter position of new element : ";
    cin>>pos;

    cout<<"\nEnter new element : ";
    cin>>tar;

    forward=AddInBetween(forward,tar,pos);
    backward=AddInBetween(backward,tar,count(backward)-pos+2);

    cout<<"\nLinked list in forward direction : ";
    display(forward);

    cout<<"\nLinked list in backward direction : ";
    display(backward);

    cout<<"\nEnter element to be deleted : ";
    cin>>tar;

    forward=DeletionByElement(forward,tar);
    backward=DeletionByElement(backward,tar);
    display(forward);
    display(backward);

    cout<<"\nEnter position of element to be deleted : ";
    cin>>pos;

    forward=DeletionByPosition(forward,pos);
    backward=DeletionByPosition(backward,count(backward)-pos+1);
    display(forward);
    display(backward);

    return 0;
}