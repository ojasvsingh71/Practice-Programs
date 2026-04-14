#include <stdio.h>

void TOH(int n, char start, char help, char des)
{
    if (n == 1)
    {
        printf("Move disk from %c to %c\n", start, des);
        return;
    }
    TOH(n - 1, start, des, help);
    printf("Move disk from %c to %c\n", start, des);
    TOH(n - 1, help, start, des);
}

void Toh(int n, char start, char stop, char temp, int *count)
{
    if (n == 1)
    {
        printf("Move disk from %c to %c\n", start, stop);
        (*count)++;
        return;
    }
    Toh(n - 1, start, temp, stop, count);
    printf("Move disk from %c to %c\n", start, stop);
    (*count)++;
    Toh(n - 1, temp, start, stop, count);
}

int main()
{
    int num;
    scanf("%d", &num);
    int count = 0;
    Toh(num, 'A', 'B', 'C', &count);
    printf("Minimum moves : %d\n", count);
}