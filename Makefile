# Most of the actions in this makefile are copied verbatim from
# https://github.com/Linaro/poplar-tools/blob/latest/build_instructions.md
# (to the point they are commented with the step numbers found in this doc)
all : \
	download_rootfs \
	clone \
	build_l_loader \
	build_linux \
	generate_image

clean :
	$(RM) -r \
		overlay/lib \
		poplar-overlay.tar.gz \
		poplar-boot.fat32 \
		poplar-usbstick.img

distclean : clean
	$(RM) -r \
		linaro-stretch-developer.tar.gz \
		overlay/root/snapshots.linaro.org \
		poplar-tools poplar-l-loader \
		poplar-arm-trusted-firmware poplar-u-boot poplar-linux \

# Step 3: Download a root file system image to use.
download_rootfs : linaro-stretch-developer.tar.gz
linaro-stretch-developer.tar.gz :
	wget \
		--recursive \
		--level 1 \
		--directory-prefix overlay/root \
		--accept 'linaro-stretch-developer-*.tar.gz' \
		https://snapshots.linaro.org/debian/images/stretch/developer-arm64/latest/
	ln -s overlay/root/snapshots.linaro.org/debian/images/stretch/developer-arm64/latest/linaro-stretch-developer-*.tar.gz linaro-stretch-developer.tar.gz


# Step 4: Get the source code.
clone : poplar-l-loader poplar-arm-trusted-firmware poplar-u-boot poplar-linux
poplar-tools :
	git clone https://github.com/linaro/poplar-tools.git -b latest
poplar-l-loader :
	git clone https://github.com/linaro/poplar-l-loader.git -b latest
poplar-arm-trusted-firmware :
	git clone https://github.com/linaro/poplar-arm-trusted-firmware.git -b latest
poplar-u-boot :
	git clone https://github.com/linaro/poplar-u-boot.git -b latest
poplar-linux :
	git clone https://github.com/linaro/poplar-linux.git -b jiancheng-usb2-test

CROSS_32=arm-linux-gnueabihf-
CROSS_64=aarch64-linux-gnu-

# Step 1: Build U-Boot.
build_uboot :
	$(MAKE) -C poplar-u-boot distclean
	$(MAKE) -C poplar-u-boot CROSS_COMPILE=${CROSS_64} poplar_defconfig
	$(MAKE) -C poplar-u-boot CROSS_COMPILE=${CROSS_64}

# Step 2: Build ARM Trusted Firmware components.
build_armtf : build_uboot
	$(MAKE) -C poplar-arm-trusted-firmware distclean
	$(MAKE) -C poplar-arm-trusted-firmware \
		CROSS_COMPILE=${CROSS_64} all fip DEBUG=1 PLAT=poplar SPD=none \
		BL33=${PWD}/poplar-u-boot/u-boot.bin

# Step 3: Build "l-loader"
build_l_loader : build_armtf
	cp poplar-arm-trusted-firmware/build/poplar/debug/bl1.bin poplar-l-loader/atf/
	cp poplar-arm-trusted-firmware/build/poplar/debug/fip.bin poplar-l-loader/atf/
	$(MAKE) -C poplar-l-loader clean
	$(MAKE) -C poplar-l-loader CROSS_COMPILE=${CROSS_32}

# Step 4: Build Linux.
build_linux :
	$(MAKE) -C poplar-linux ARCH=arm64 CROSS_COMPILE="${CROSS_64}" \
		defconfig
	$(MAKE) -C poplar-linux ARCH=arm64 CROSS_COMPILE="${CROSS_64}" \
		all -j $(shell nproc)

generate_image : poplar-boot.fat32 poplar-overlay.tar.gz
	guestfish -f genimage.fish

# Currently guestfish offers no way to force FAT32 when creating a vfat
# filesystem. The poplar boot ROM only supports FAT32 so we have to
# pre-format the boot filesystem ready to use in the main guestfish script.
poplar-boot.fat32 : Makefile
	guestfish sparse poplar-boot.fat32 128M
	mkfs.vfat -F 32 -n BOOT poplar-boot.fat32

poplar-overlay.tar.gz :
	$(RM) -r overlay/lib/modules
	$(MAKE) -C poplar-linux ARCH=arm64 CROSS_COMPILE="${CROSS_64}" \
		modules_install INSTALL_MOD_PATH=${PWD}/overlay
	tar --group 0 --owner 0 -C overlay -czf poplar-overlay.tar.gz .

.PHONY : poplar-overlay.tar.gz
