#include<iostream>
using namespace std;

struct TreeNode{
    int val;
    struct TreeNode* left;
    struct TreeNode* right;

    TreeNode():val(0),left(nullptr),right(nullptr){}
    TreeNode(int x):val(x),left(nullptr),right(nullptr){}
    TreeNode(int x,TreeNode* lefti,TreeNode* righti):val(x),left(lefti),right(righti){}
};

TreeNode* insert(TreeNode* root,int x){
    if(!root){
        return new TreeNode(x);
    }else if(x>root->val){
        root->right=insert(root->right,x);
    }else if(x<root->val){
        root->left=insert(root->left,x);
    }else{
        cout<<"Duplicate elements not allowed\n";
    }return root;
}

TreeNode* minValue(TreeNode* root){
    while(root->left){
        root=root->left;
    }return root;
}

TreeNode* maxValue(TreeNode* root){
    while(root->right){
        root=root->right;
    }return root;
}

TreeNode* deletion(TreeNode* root,int x){    
    if(!root){
        cout<<"Node not found"<<endl;
        return root;
    }else if(x>root->val){
        root->right=deletion(root->right,x);
    }else if(x<root->val){
        root->left=deletion(root->left,x);
    }else{
        if(!root->left){
            cout<<root->val<<"Deleted\n";
            root=root->right;
            return root;
        }else if(!root->right){
            cout<<root->val<<" Deleted\n";
            root=root->left;
            return root;
        }else{
            TreeNode* temp=minValue(root->right);
            root->val=temp->val;
            root->right=deletion(root->right,temp->val);
        }
    }return root;  
}

void inorder(TreeNode* root){
    if(root){
        inorder(root->left);
        cout<<root->val<<" ";
        inorder(root->right);
    }
}

void search(TreeNode* root,int x){
    if(!root){
        cout<<"\nNode not found !!!\n";
    }else if(x>root->val){
        search(root->right,x);
    }else if(x<root->val){
        search(root->left,x);
    }else{
        cout<<"\nFound Node !!!\n";
    }
}

int main(){
    int num,tar;
    TreeNode* bu=NULL;

    cout<<"\nEnter total number of nodes to be inserted : \n";
    cin>>num;
    cout<<"\nEnter the node values : \n";
    while(num--){
        int data;
        cin>>data;
        bu=insert(bu,data);
    }

    cout<<"\nInorder of the above BST is : \n";
    inorder(bu);

    cout<<"\nEnter element to delete : \n";
    cin>>tar;
    bu=deletion(bu,tar);

    cout<<"\nBST after deletion : \n";
    inorder(bu);

    cout<<"\nEnter element to search : \n";
    cin>>tar;
    search(bu,tar);

    TreeNode* temp=minValue(bu);
    cout<<"\nMaximum element in the tree : "<<temp->val;

    temp=maxValue(bu);
    cout<<"\nMinimum element in the tree : "<<temp->val;

    return 0;
}