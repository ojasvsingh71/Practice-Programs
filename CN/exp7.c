#include <stdio.h>
#include <string.h>
#include <stdlib.h>

// Function Prototypes
void character_count();
void character_stuffing();
void bit_stuffing();

int main() {
    int choice;

    while (1) {
        printf("\n=================================\n");
        printf("    DATA LINK LAYER FRAMING\n");
        printf("=================================\n");
        printf("1. Character Count\n");
        printf("2. Character Stuffing\n");
        printf("3. Bit Stuffing\n");
        printf("4. Exit\n");
        printf("Enter your choice: ");
        
        if (scanf("%d", &choice) != 1) {
            printf("Invalid input. Exiting.\n");
            break;
        }

        switch (choice) {
            case 1:
                character_count();
                break;
            case 2:
                character_stuffing();
                break;
            case 3:
                bit_stuffing();
                break;
            case 4:
                printf("Exiting program.\n");
                exit(0);
            default:
                printf("Invalid choice. Please try again.\n");
        }
    }
    return 0;
}

// 1. Character Count Implementation
void character_count() {
    int num_frames;
    char frames[10][100];
    char stream[1000] = "";
    char temp[110];

    printf("\n--- Character Count ---\n");
    printf("Enter the number of frames: ");
    scanf("%d", &num_frames);

    // Sender side
    for (int i = 0; i < num_frames; i++) {
        printf("Enter data for frame %d (no spaces): ", i + 1);
        scanf("%s", frames[i]);
        
        // Count = length of string + 1 (for the count digit itself)
        int count = strlen(frames[i]) + 1;
        sprintf(temp, "%d%s", count, frames[i]);
        strcat(stream, temp);
    }
    
    printf("\n[SENDER] Transmitted Stream: %s\n", stream);

    // Receiver side
    printf("[RECEIVER] Decoded Frames:\n");
    int i = 0;
    int len = strlen(stream);
    int frame_num = 1;

    while (i < len) {
        int count = stream[i] - '0'; // Convert char to int
        printf("Frame %d: ", frame_num++);
        
        for (int j = 1; j < count && (i + j) < len; j++) {
            printf("%c", stream[i + j]);
        }
        printf("\n");
        i += count; // Jump to the next frame
    }
}

// 2. Character Stuffing Implementation
void character_stuffing() {
    char data[100];
    char stuffed[200];
    char destuffed[100];
    char flag = 'F';
    char esc = 'E';

    printf("\n--- Character Stuffing ---\n");
    printf("Using Flag = 'F' and Escape = 'E'\n");
    printf("Enter data string (no spaces): ");
    scanf("%s", data);

    // Sender side (Stuffing)
    int j = 0;
    stuffed[j++] = flag; // Starting flag
    
    for (int i = 0; data[i] != '\0'; i++) {
        if (data[i] == flag || data[i] == esc) {
            stuffed[j++] = esc; // Stuff escape character
        }
        stuffed[j++] = data[i];
    }
    
    stuffed[j++] = flag; // Ending flag
    stuffed[j] = '\0';
    
    printf("\n[SENDER] Transmitted Stream: %s\n", stuffed);

    // Receiver side (Destuffing)
    j = 0;
    int len = strlen(stuffed);
    
    for (int i = 1; i < len - 1; i++) { // Skip outer flags
        if (stuffed[i] == esc) {
            i++; // Skip the stuffed escape character
        }
        destuffed[j++] = stuffed[i];
    }
    destuffed[j] = '\0';
    
    printf("[RECEIVER] Decoded Data: %s\n", destuffed);
}

// 3. Bit Stuffing Implementation
void bit_stuffing() {
    char data[100];
    char stuffed[200];
    char destuffed[100];
    const char* flag = "01111110";

    printf("\n--- Bit Stuffing ---\n");
    printf("Enter binary data string (e.g., 111111): ");
    scanf("%s", data);

    // Sender side (Stuffing)
    int count = 0, j = 0;
    strcpy(stuffed, flag); // Add starting flag
    j = 8;

    for (int i = 0; data[i] != '\0'; i++) {
        if (data[i] == '1') {
            count++;
            stuffed[j++] = '1';
        } else {
            count = 0;
            stuffed[j++] = '0';
        }

        if (count == 5) {
            stuffed[j++] = '0'; // Stuff a zero after five 1s
            count = 0;
        }
    }
    stuffed[j] = '\0';
    strcat(stuffed, flag); // Add ending flag
    
    printf("\n[SENDER] Transmitted Stream: %s\n", stuffed);

    // Receiver side (Destuffing)
    count = 0;
    j = 0;
    int len = strlen(stuffed);

    // Loop from 8 to len-8 to ignore the flags
    for (int i = 8; i < len - 8; i++) {
        if (stuffed[i] == '1') {
            count++;
            destuffed[j++] = '1';
        } else {
            count = 0;
            destuffed[j++] = '0';
        }

        if (count == 5) {
            i++; // Skip the stuffed zero
            count = 0;
        }
    }
    destuffed[j] = '\0';
    
    printf("[RECEIVER] Decoded Data: %s\n", destuffed);
}