#include <stdio.h>
#include <stdlib.h>

struct node
{
    int data;
    struct node *left;
    struct node *right;
};
typedef struct node *NODE;

NODE add(int data)
{
    NODE temp = malloc(sizeof(struct node));
    temp->left = NULL;
    temp->right = NULL;
    temp->data = data;
    return temp;
}

void print(NODE head)
{
    if (head != NULL)
    {
        print(head->left);
        printf("%d ", head->data);
        print(head->right);
    }
}

int main()
{
    NODE bu = NULL;
    bu = add(7);
    bu->left = add(9);
    bu->left->right=add(70);
    bu->left->left=add(89);
    bu->right = add(10);
    bu->right->left=add(30);
    bu->right->right=add(40);

    print(bu);   //OUTPUT:- 89 9 70 7 30 10 40 
}