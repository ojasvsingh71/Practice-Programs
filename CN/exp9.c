#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// Function to determine the IP Class based on the first octet
void determine_class(int first_octet, char* ip_class) {
    if (first_octet >= 0 && first_octet <= 127) {
        strcpy(ip_class, "Class A");
    } else if (first_octet >= 128 && first_octet <= 191) {
        strcpy(ip_class, "Class B");
    } else if (first_octet >= 192 && first_octet <= 223) {
        strcpy(ip_class, "Class C");
    } else if (first_octet >= 224 && first_octet <= 239) {
        strcpy(ip_class, "Class D");
    } else if (first_octet >= 240 && first_octet <= 255) {
        strcpy(ip_class, "Class E");
    } else {
        strcpy(ip_class, "Invalid");
    }
}

// Function to convert an integer (0-255) to an 8-bit binary string
void dec_to_bin(int num, char* bin_str) {
    for (int i = 7; i >= 0; i--) {
        // Use bitwise AND to check if the i-th bit is 1 or 0
        bin_str[7 - i] = (num & (1 << i)) ? '1' : '0';
    }
    bin_str[8] = '\0'; // Null-terminate the string
}

int main() {
    char ip[20];
    int o1, o2, o3, o4;
    char ip_class[20];
    char b1[9], b2[9], b3[9], b4[9];

    printf("\n=================================\n");
    printf("       IPv4 ADDRESS ANALYZER       \n");
    printf("=================================\n");
    
    printf("Enter IPv4 Address (e.g., 192.168.1.1): ");
    if (scanf("%19s", ip) != 1) {
        printf("Error reading input.\n");
        return 1;
    }

    // Parse the dotted decimal string into four integers
    if (sscanf(ip, "%d.%d.%d.%d", &o1, &o2, &o3, &o4) != 4) {
        printf("Error: Invalid IP format. Please use dotted-decimal format.\n");
        return 1;
    }

    // Validate that all octets are within the valid 0-255 range
    if (o1 < 0 || o1 > 255 || o2 < 0 || o2 > 255 || o3 < 0 || o3 > 255 || o4 < 0 || o4 > 255) {
        printf("Error: Invalid IP. Each octet must be between 0 and 255.\n");
        return 1;
    }

    // 1. Get Class
    determine_class(o1, ip_class);

    // 2. Convert each octet to an 8-bit binary string
    dec_to_bin(o1, b1);
    dec_to_bin(o2, b2);
    dec_to_bin(o3, b3);
    dec_to_bin(o4, b4);

    // Output the results
    printf("\n--- Analysis Results ---\n");
    printf("Entered IP:     %s\n", ip);
    printf("Network Class:  %s\n", ip_class);
    printf("Binary IP:      %s.%s.%s.%s\n", b1, b2, b3, b4);
    printf("32-bit Address: %s%s%s%s\n", b1, b2, b3, b4);

    return 0;
}