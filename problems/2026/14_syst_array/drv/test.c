#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define DEVICE "/dev/sa-dev"
#define SIZE 4
#define PAGE 4096

int main(void)
{
    int fd = open(DEVICE, O_RDWR);
    if (fd < 0) {
        perror("open");
        return 1;
    }

    uint16_t *a = aligned_alloc(PAGE, PAGE);
    uint16_t *c = aligned_alloc(PAGE, PAGE);

    if (!a || !c)
        return 1;

    for (int i = 0; i < PAGE / 2; i++)
        a[i] = 5;

    uint32_t addrs[2];
    addrs[0] = (uintptr_t)a;
    addrs[1] = (uintptr_t)c;

    if (write(fd, addrs, sizeof(addrs)) < 0) {
        perror("write");
        return 1;
    }

    printf("Result:\n");
    for (int i = 0; i < SIZE; i++) {
        for (int j = 0; j < SIZE; j++)
            printf("%u ", c[i * SIZE + j]);
        printf("\n");
    }

    close(fd);
    return 0;
}