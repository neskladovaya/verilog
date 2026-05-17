#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>

static unsigned long find_max(int fd, int kmalloc_mode)
{
    unsigned long lo = 0;
    unsigned long hi = 1;
    int cmd = kmalloc_mode ? _IOW('M', 1, unsigned)
                           : _IOW('M', 2, unsigned);

    while (ioctl(fd, cmd, hi) == 0) {
        lo = hi;
        hi <<= 1;
    }

    return lo;
}

int main(void)
{
    int fd = open("/dev/alloc", O_RDWR);
    if (fd < 0) {
        perror("open");
        return 1;
    }

    printf("kmalloc test\n");
    unsigned long k = find_max(fd, 1);
    printf("max: %lu MB\n", k >> 20);
    ioctl(fd, _IO('M', 3));

    printf("\nvmalloc test\n");
    unsigned long v = find_max(fd, 0);
    printf("max: %lu MB\n", v >> 20);
    ioctl(fd, _IO('M', 4));

    close(fd);
    return 0;
}
