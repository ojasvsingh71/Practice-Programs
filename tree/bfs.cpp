#include<bits/stdc++.h>
#include<deque>
using namespace std;

struct TreeNode{
    int val;
    TreeNode* left;
    TreeNode* right;

    TreeNode():val(0),left(nullptr),right(nullptr){}
    TreeNode(int x):val(x),left(nullptr),right(nullptr){}
};

void bfs(TreeNode* root){
    deque<TreeNode*> dq;
    dq.push_back(root);
    while(!dq.empty()){
        int n=dq.size();
        for(int i=0;i<n;i++){
            printf("%d ",dq.front()->val);
            if(dq.front()->left) dq.push_back(dq.front()->left);
            if(dq.front()->right) dq.push_back(dq.front()->right);
            dq.pop_front();
        }
    }
}

int main(){
    TreeNode* root=new TreeNode(10);
    root->left=new TreeNode(20);
    root->right=new TreeNode(30);
    root->left->left=new TreeNode(40);
    root->left->right=new TreeNode(50);
    root->right->left=new TreeNode(60);
    root->right->right=new TreeNode(70);

    bfs(root);
}