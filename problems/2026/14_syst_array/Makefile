LINUX = linux-xlnx
UBOOT = u-boot-xlnx
DTXLNX = device-tree-xlnx

UIMAGE = $(LINUX)/build/arch/arm/boot/uImage

export CROSS_COMPILE = arm-none-linux-gnueabihf-

all: project impl dtb vitis uboot linux drv bootgen uramdisk.image.gz boot.scr

download:
	wget https://xilinx-wiki.atlassian.net/wiki/download/attachments/18842473/arm_ramdisk.image.gz -O ramdisk.image.gz 
	git clone --branch xilinx-v2025.1 --depth 1 https://github.com/Xilinx/linux-xlnx.git $(LINUX)
	git clone --branch xilinx-v2025.1 --depth 1 https://github.com/Xilinx/u-boot-xlnx.git $(UBOOT)
	git clone --branch xlnx_rel_v2025.1 https://github.com/Xilinx/device-tree-xlnx.git $(DTXLNX)


uramdisk.image.gz: ramdisk.image.gz
	mkimage -A arm -T ramdisk -C gzip -d ramdisk.image.gz uramdisk.image.gz

boot.scr: boot.cmd
	mkimage -A arm -T script -d boot.cmd boot.scr

clean:
	rm -rf *.log *.jou .Xil
	rm -rf fpga
	rm -rf vitis
	rm -rf *.dtsi *.dtb *.mss include
	rm -rf BOOT.bin
	rm -rf uramdisk.image.gz boot.scr
	rm -rf $(LINUX)/build
	rm -rf $(UBOOT)/build

project:
	vivado -mode batch -source project.tcl

impl:
	vivado -mode batch -source impl.tcl

vitis:
	vitis -s build.py

dtb:
	dtc -I dts -O dtb -o system.dtb system.dts		

drv:
	$(MAKE) -C drv

linux:
	make -C $(LINUX) O=build ARCH=arm xilinx_zynq_defconfig
	make -C $(LINUX) O=build ARCH=arm modules_prepare 
	make -C $(LINUX) O=build ARCH=arm modules
	make -C $(LINUX) O=build ARCH=arm UIMAGE_LOADADDR=0x8000 -j`nproc` uImage

uboot:
	make -C $(UBOOT) O=build ARCH=arm xilinx_zynq_virt_defconfig
	mkdir -p $(UBOOT)/build/arch/arm/dts
	cp system.dtb $(UBOOT)/build/arch/arm/dts
	make -C $(UBOOT) O=build ARCH=arm DEVICE_TREE=system -j`nproc`

bootgen:
	bootgen -image input.bif -arch zynq -o BOOT.bin -w on

flash:
	rm -rf $(SDCARD)/*
	cp -f BOOT.bin $(SDCARD)
	cp -f system.dtb $(SDCARD)
	cp -f $(UIMAGE) $(SDCARD)
	cp -f uramdisk.image.gz $(SDCARD)
	cp -f boot.scr $(SDCARD)
	cp -f drv/sa.ko $(SDCARD)
	cp -f drv/test $(SDCARD)
	sync $(SDCARD)

gui:
	vivado fpga/fpga.xpr

.PHONY: all clean gui project bootgen flash vitis impl xsct dtb linux uboot download

