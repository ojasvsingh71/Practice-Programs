#include<iostream>
using namespace std;

struct TreeNode{
    int val;
    struct TreeNode* left;
    struct TreeNode* right;

    TreeNode():val(0),left(nullptr),right(nullptr){}
    TreeNode(int x):val(x),left(nullptr),right(nullptr){}
    TreeNode(int x,TreeNode* lefi,TreeNode* righti):val(x),left(lefi),right(righti){}
};

TreeNode* add(TreeNode* root,int x){
    if(!root) return new TreeNode(x);
    if(x>root->val){
        root->right=add(root->right,x);
    }else{
        root->left=add(root->left,x);
    }
}

void preorder(TreeNode* root){
    if(root){
        cout<<root->val<<" ";
        preorder(root->left);
        preorder(root->right);
    }
}

void inorder(TreeNode* root){
    if(root){
        inorder(root->left);
        cout<<root->val<<" ";
        inorder(root->right);
    }
}

void postorder(TreeNode* root){
    if(root){
        postorder(root->left);
        postorder(root->right);
        cout<<root->val<<" ";
    }
}

int main(){
    int num;
    TreeNode* bu=NULL;

    cin>>num;
    while(num--){
        int data;
        cin>>data;
        bu=add(bu,data);
    }

    preorder(bu);
    cout<<endl;
    inorder(bu);
    cout<<endl;
    postorder(bu);

    return 0;
}