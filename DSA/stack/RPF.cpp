#include<iostream>
using namespace std;

int stack[1000];
int top=-1;

int isop(char ch){
    if(ch=='+' || ch=='-' || ch=='*' || ch=='/') return 1;
    return 0;
}

int op(int a,int b,int op){
    if(op=='+') return a+b;
    else if(op=='-') return a-b;
    else if(op=='*') return a*b;
    else return a/b;
}

int evaluate(char str[]){
    for(int i=0;str[i]!=0;i++){
        char ch=str[i];

        if(isop(ch)){
            int a=stack[top--];
            int b=stack[top--];
            int ans=op(b,a,ch);
            stack[++top]=ans;
        }else{
            stack[++top]=ch-'0';
        }
    }return stack[top];
}

int main(){
    char bu[1000];
    cout<<"Enter the string : ";
    cin>>bu;

    cout<<"Result : "<<evaluate(bu)<<endl;

    return 0;
}