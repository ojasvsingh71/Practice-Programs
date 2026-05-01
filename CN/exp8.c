#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// Function to perform Modulo-2 division and find the remainder
void calculate_crc(const char *data, const char *poly, char *remainder) {
    int data_len = strlen(data);
    int poly_len = strlen(poly);
    char temp[1024];
    
    // Copy data to a temporary array to perform division
    strcpy(temp, data);

    // Perform XOR division
    for (int i = 0; i <= data_len - poly_len; i++) {
        // If the leading bit is 1, XOR with the polynomial
        if (temp[i] == '1') {
            for (int j = 0; j < poly_len; j++) {
                temp[i + j] = (temp[i + j] == poly[j]) ? '0' : '1';
            }
        }
    }

    // The remainder is the last (poly_len - 1) bits of the temp array
    strncpy(remainder, temp + data_len - poly_len + 1, poly_len - 1);
    remainder[poly_len - 1] = '\0';
}

int main() {
    char data[512], poly[128];
    char appended_data[1024], remainder[128], codeword[1024], received[1024];
    int choice;

    while (1) {
        printf("\n=================================\n");
        printf("    CYCLIC REDUNDANCY CHECK (CRC) \n");
        printf("=================================\n");
        printf("Select Generator Polynomial:\n");
        printf("1. CRC-8  (x^8 + x^2 + x + 1) -> 100000111\n");
        printf("2. CRC-16 (x^16 + x^15 + x^2 + 1) -> 11000000000000101\n");
        printf("3. Custom Polynomial\n");
        printf("4. Exit\n");
        printf("Enter your choice: ");
        
        if (scanf("%d", &choice) != 1) {
            printf("Invalid input.\n");
            break;
        }

        if (choice == 4) {
            printf("Exiting...\n");
            break;
        }

        if (choice == 1) {
            strcpy(poly, "100000111");
        } else if (choice == 2) {
            strcpy(poly, "11000000000000101");
        } else if (choice == 3) {
            printf("Enter custom binary polynomial (e.g., 1011): ");
            scanf("%s", poly);
        } else {
            printf("Invalid choice. Try again.\n");
            continue;
        }

        // 1. Get Data
        printf("\nEnter Data Word (binary): ");
        scanf("%s", data);

        // 2. Append Zeros (number of zeros = degree of polynomial = poly_len - 1)
        int poly_len = strlen(poly);
        strcpy(appended_data, data);
        for (int i = 0; i < poly_len - 1; i++) {
            strcat(appended_data, "0");
        }

        printf("\n--- SENDER SIDE ---\n");
        printf("Data with appended zeros: %s\n", appended_data);

        // 3. Calculate Remainder
        calculate_crc(appended_data, poly, remainder);
        printf("Calculated CRC (Remainder): %s\n", remainder);

        // 4. Form Codeword (Original Data + Remainder)
        strcpy(codeword, data);
        strcat(codeword, remainder);
        printf("Transmitted Codeword: %s\n", codeword);

        // 5. Receiver Side Simulation
        printf("\n--- RECEIVER SIDE ---\n");
        printf("Enter received codeword (Copy above to test SUCCESS, or change bits to test ERROR): ");
        scanf("%s", received);

        // 6. Check Received Data
        char check_remainder[128];
        calculate_crc(received, poly, check_remainder);
        
        printf("Receiver CRC (Remainder): %s\n", check_remainder);

        // 7. Validate (If remainder contains any '1', there is an error)
        int error_detected = 0;
        for (int i = 0; i < strlen(check_remainder); i++) {
            if (check_remainder[i] == '1') {
                error_detected = 1;
                break;
            }
        }

        if (error_detected) {
            printf("[!] STATUS: ERROR DETECTED! The frame is corrupted and will be discarded.\n");
        } else {
            printf("[+] STATUS: NO ERROR. The frame is accepted.\n");
        }
    }
    return 0;
}