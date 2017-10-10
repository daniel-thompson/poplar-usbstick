#!/usr/bin/guestfish -f

sparse poplar-usbstick.img 2048M
run

# Construct the partition table
part-init /dev/sda mbr
part-add /dev/sda p 2048 264191
part-set-mbr-id /dev/sda 1 0xc
part-set-bootable /dev/sda 1 true
part-add /dev/sda p 264192 -1
mkfs ext4 /dev/sda2 label:ROOTFS

# The rootfs is currently empty
mount /dev/sda2 /

# "Format" /dev/sda1 (see comment in Makefile)
copy-in poplar-boot.fat32 /
copy-file-to-device /poplar-boot.fat32 /dev/sda1
rm /poplar-boot.fat32

# Populate the root filesystem
tar-in linaro-stretch-developer.tar.gz / compress:gzip
glob mv /binary/* /
rmdir /binary

# Populate the boot filesystem
mkdir-p /boot
mount /dev/sda1 /boot
mkdir-p /boot/extlinux
copy-in poplar-l-loader/fastboot.bin /boot
copy-in poplar-linux/arch/arm64/boot/Image /boot
mkdir-p /boot/hisilicon
copy-in poplar-linux/arch/arm64/boot/dts/hisilicon/hi3798cv200-poplar.dtb /boot/hisilicon

# Apply the overlay
tar-in poplar-overlay.tar.gz / compress:gzip

# Make a simple "happy noise"
list-filesystems

