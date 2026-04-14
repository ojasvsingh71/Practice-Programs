#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int op(char *hu, int a, int b)
{
    if (strcmp(hu, "+") == 0)
        return a + b;
    else if (strcmp(hu, "-") == 0)
        return a - b;
    else if (strcmp(hu, "*") == 0)
        return a * b;
    return a / b;
}

int isop(char *hu)
{
    if (strcmp(hu, "+") == 0 || strcmp(hu, "-") == 0 || strcmp(hu, "*") == 0 || strcmp(hu, "/") == 0)
        return 1;
    return 0;
}

int stack[100];
char oper[100];
int top = -1;

int main()
{
    int num;
    char token[20];
    scanf("%d", &num);
    for (int i = 0; i < num; i++)
    {
        scanf("%s", token);
        if (isop(token))
        {
            int a = stack[top--];
            int b = stack[top--];
            int ans = op(token, a, b);
            stack[++top] = ans;
        }
        else
        {
            stack[++top] = atoi(token);
        }
    }
    printf("%d\n", stack[top]);
}