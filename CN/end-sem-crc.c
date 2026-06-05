#include <stdio.h>
#include <string.h>

char data[100], concatData[100], generator[30], remainderStr[30];
int dataLen, genLen;

void xorOperation()
{
    for (int c = 1; c < genLen; c++)
    {
        remainderStr[c - 1] = ((remainderStr[c] == generator[c]) ? '0' : '1');
    }
}
void computeCRC()
{
    for (int i = 0; i < genLen; i++)
        remainderStr[i] = concatData[i];

    for (int i = genLen; i <= dataLen + genLen - 1; i++)
    {
        if (remainderStr[0] == '1')
        {
            xorOperation();
        }
        else
        {
            for (int c = 1; c < genLen; c++)
                remainderStr[c - 1] = remainderStr[c];
        }
        remainderStr[genLen - 1] = concatData[i];
    }
}
int main()
{
    printf("Enter raw binary data: ");
    scanf("%s", data);

    printf("Enter generator polynomial string: ");
    scanf("%s", generator);

    dataLen = strlen(data);
    genLen = strlen(generator);
 
    strcpy(concatData, data);

    for (int i = 0; i < genLen - 1; i++)
        strcat(concatData, "0");

    computeCRC();

    printf("Calculated Remainder Checksum: ");

    for (int i = 0; i < genLen - 1; i++)
        printf("%c", remainderStr[i]);

    printf("\n");
    
    printf("Final Transmitted Frame: %s", data);

    printf("\n");
    
    return 0;
}