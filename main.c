#include "defang_ip_addr.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main() {
    // Test cases
    char *test_cases[] = {"1.1.1.1",  "255.100.50.0", "192.168.1.1",
                          "10.0.0.1", "no.dots.here", ""};

    int num_tests = sizeof(test_cases) / sizeof(test_cases[0]);

    for (int i = 0; i < num_tests; i++) {
        printf("Original: \"%s\"\n", test_cases[i]);

        char *result = defang_ip_addr(test_cases[i]);

        if (result != NULL) {
            printf("Defanged: \"%s\"\n", result);
            free(result);
        } else {
            printf("Error: malloc failed\n");
        }

        printf("---\n");
    }

    return 0;
}