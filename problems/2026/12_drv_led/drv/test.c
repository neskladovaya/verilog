#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>

int main(void)
{
    int fd = open("/dev/led", O_WRONLY);
    if (fd < 0) {
        perror("open");
        return 1;
    }

    uint8_t a = 0x5; // 0101
    uint8_t b = 0xA; // 1010

    while (1) {
        write(fd, &a, 1);
        usleep(200000);

        write(fd, &b, 1);
        usleep(200000);
    }

    close(fd);
    return 0;
}