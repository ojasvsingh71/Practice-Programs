#include<iostream>
#include<deque>
#include<vector>
using namespace std;

struct TreeNode{
    int val;
    struct TreeNode* left;
    struct TreeNode* right;

    TreeNode() : val(0),left(nullptr),right(nullptr){}
    TreeNode(int x) : val(x),left(nullptr),right(nullptr){}
    TreeNode(int x , TreeNode* left,TreeNode* right) : val(x),left(left),right(right){}
};

void LevelOrder(TreeNode* root){
    if(!root) return ;
    deque<TreeNode*> dq;
    dq.push_back(root);
    while(!dq.empty()){
        int size=dq.size();
        for(int i=0;i<size;i++){
            TreeNode* curr=dq.front();
            dq.pop_front();

            printf("%d ",curr->val);

            if(curr->left) dq.push_back(curr->left);
            if(curr->right) dq.push_back(curr->right);
        }
    }
}

TreeNode* insert(TreeNode* root,int x){
    if(!root){
        root=new TreeNode(x);
        return root;
    }else if(x<root->val){
        root->left=insert(root->left,x);
    }else if(x>root->val){
        root->right=insert(root->right,x);
    }else{
        printf("Duplicate values\n");
        return root;
    }
}

void inorder(TreeNode* root){
    if(root){
        inorder(root->left);
        printf("%d ",root->val);
        inorder(root->right);
    }
}

int main(){
    TreeNode* bu=NULL;
    bu=insert(bu,10);
    bu=insert(bu,200);
    bu=insert(bu,50);
    bu=insert(bu,90);
    bu=insert(bu,100);
    bu=insert(bu,110);
    
    inorder(bu);
    cout<<endl;
    LevelOrder(bu);

    return 0;
}
