CROSS_COMPILE ?= arm-none-linux-gnueabihf-
ARCH ?= arm
obj-m := sa.o

KERNELDIR ?= ../linux-xlnx/build
PWD := $(shell pwd)

all:
	$(MAKE) -C $(KERNELDIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) M=$(PWD) modules

test:
	$(CROSS_COMPILE)gcc -static -o test test.c

clean:
	$(MAKE) -C $(KERNELDIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE)  M=$(PWD) clean
	rm -f test

