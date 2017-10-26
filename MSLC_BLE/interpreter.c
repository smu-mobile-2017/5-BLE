#include <stdio.h>
#include <stdlib.h>

#include <string.h>

// Temp vars
int bt_state = 0, m_state = 0, p_state = 0, r_state = 0, g_state = 0, b_state;


void interpret(char* command, char* buffer) {
    char* token = strtok(command, " "); // Tokenize the command

    //Compare the command identifier
    if (token[0] == 'm') { // Moter command
        token = strtok(NULL, " ");
        m_state = atoi(token);
    } else if (token[0] == 'l') { // LED command ('l 233 123 85')
        token = strtok(NULL, " ");  // Get next str ('233')
        r_state = atoi(token);
        token = strtok(NULL, " ");  // Get next str ('123')
        g_state = atoi(token);
        token = strtok(NULL, " ");  // Get final str ('85');
        b_state = atoi(token);
    } else if (token[0] == 'r') { // Response command
        sprintf(buffer, "b %d\n", bt_state); // Added button value to return
        sprintf(buffer, "m %d\n", m_state);  // Moter state (0-180)
        sprintf(buffer, "p %d\n", p_state);  // Potentiometer (0-4096)
        sprintf(buffer, "r %d %d %d\n", r_state, g_state, b_state); //LED (0-255 0-255 0-255)
    } else { // Error state
        printf("ERROR IN INTERPRETING THE COMMAND\n");
    }
}

int main(int argc, char const *argv[]) {
    // Command to interpret
    char cmd[256] = {'g'};

    // Create buffer
    char* buffer = malloc(sizeof(char)*256);
    interpret(cmd, buffer);

    printf("%s", buffer);

    // Free buffer
    free(buffer);
    return 0;
}
