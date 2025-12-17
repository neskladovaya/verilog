#define UARTDR 0x9000000
#define MULDEV 0x9008000

#define MULDEV_A   (MULDEV + 0x8)   
#define MULDEV_B   (MULDEV + 0x10)   
#define MULDEV_RES (MULDEV + 0x20)  

typedef unsigned char uint8_t;
typedef long unsigned int uint64_t;

void pl011_putc(const uint8_t c) {
    *(volatile uint8_t *)UARTDR = c;
}

void muldev_set_a(const uint64_t n) {
    *(volatile uint64_t *)MULDEV_A = n;
}

void muldev_set_b(const uint64_t n) {
    *(volatile uint64_t *)MULDEV_B = n;
}

uint64_t muldev_get_result() {
    return *(volatile uint64_t *)MULDEV_RES;
}

/* вывести uint64_t как десятичную строку через UART */
void print_u64_dec(uint64_t v) {
    char buf[32];
    int i = 0;
    if (v == 0) {
        pl011_putc('0');
        return;
    }
    while (v > 0) {
        buf[i++] = '0' + (v % 10);
        v /= 10;
    }
    /* вывести в обратном порядке */
    for (int j = i - 1; j >= 0; j--) {
        pl011_putc((uint8_t)buf[j]);
    }
}

void entry() {
    muldev_set_a(6);
    muldev_set_b(7);

    uint64_t res = muldev_get_result();
    print_u64_dec(res);
    pl011_putc('\n');
}
