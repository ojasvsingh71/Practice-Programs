#include<iostream>
using namespace std;

struct node{
    int val;
    struct node* left;
    struct node* right;
};
typedef struct node* bu;

bu create(int x){
    bu temp=(bu)malloc(sizeof(struct node));
    temp->val=x;
    temp->left=temp->right=NULL;
    return temp;
}

bu add(bu root,int arr[],int n){
    if(n==0) return NULL;

    bu queue[1000];
    int front=0,rear=0;

    root=create(arr[0]);
    queue[rear++]=root;

    int i=1;
    while(i<n){
        bu curr=queue[front++];
        if(i<n){
            curr->left=create(arr[i++]);
            queue[rear++]=curr->left;
        }if(i<n){
            curr->right=create(arr[i++]);
            queue[rear++]=curr->right;
        }
    }
    return root;
}

int doing(bu node,int* dia){
    if(!node) return 0;

    int lh=doing(node->left,dia);
    int rh=doing(node->right,dia);

    int loc_dia=lh+rh;
    if(loc_dia>*dia){
        * dia=loc_dia;
    }

    return 1+max(lh,rh);
}

int diameter(bu node){
    int dia=0;
    doing(node,&dia);
    return dia;
}

void inorder(bu root){
    if(root){
        inorder(root->left);
        printf("%d ",root->val);
        inorder(root->right);
    }
}

void postorder(bu root){
    if(root){
        postorder(root->left);
        postorder(root->right);
        printf("%d ",root->val);
    }
}

int main(){
    int arr[1000];
    int n=0,data;
    
    while(true){
        scanf("%d",&data);
        if(data==-1) break;
        arr[n++]=data;
    }

    for(int i=0;i<n;i++){
        printf("%d ",arr[i]);
    }printf("\n");

    bu root=NULL;

    root=add(root,arr,n);

    inorder(root);

    cout<<"\nDiameter of Tree is : "<<diameter(root);
}