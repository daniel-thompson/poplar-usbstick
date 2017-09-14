Stretch Installer for Poplar
============================

This installer is the result of an unofficial skunkworks project and
it intended to make it easy to start GNU/Linux development on poplar.
In order to manage expectations, it is not a polished product and the
provided kernel has a limited feature set.

Nevertheless it provides a good basis for kernel development; self
compiled kernels can easily be added to the boot image and u-boot can 
be configured to provide a menu to choose between a development and
fallback kernel.

The installer will install:

 * mmcblk0p1 (raw): Bootloaders (early loader, ARM Trusted Firmware and u-boot)
 * mmcblk0p2 (vfat): Kernel, device tree and boot config files
 * mmcblk0p3 (f2fs): Linaro stretch developer image (a custom Debian derived
   filesystem image.

Creating install media
----------------------

Copy the installer image to a USB flash drive. Assuming the drive
enumarates as /dev/sdb then unmount any automounted partitons and then try:

    sudo dd if=poplar-usbstick.img of=/dev/sdb bs=4096

Warning: This will destroy all data currently held on the USB flash drive.

Booting the install media
-------------------------

1. Connect your PC to the mirco-B connector on the board and bring up
   a terminal emulator and set the baud rate to 115200.
2. Insert the install media into one of the USB 2.0 sockets (front of
   board, marked JX22).
3. Hold down the USB_BOOT button (also marked S3), then press and
   release RST_BTN_N (also marked S4).
4. You should see u-boot start and debian will boot (first time boot
   can take a little extra time as the root partition is expanded to
   fill the USB stick.

Installation
------------

1. At the root prompt run ./install.sh and follow the on-screen prompts
2. Make a cup of tea or coffee; the root filesystem consists of almost 
   40,000 files and takes a long time to unpack.

Installing a second kernel
--------------------------

u-boot can be configured to offer a menu during boot. This allows you to
install additional kernels in /boot, retaining access to a known working
kernel that can be used as a fallback if the new kernel cannot boot.

The following example /boot/extlinux/extlinux.conf file shows how this
is achieved in practice:

~~~
menu title Welcome to poplar!
default Debian
timeout 3

label Debian
        kernel ../Image
        append loglevel=4 root=/dev/mmcblk0p3 rw rootwait
        fdtdir ../

label Debian (new kernel)
	kernel ../Image-new
        append earlycon root=/dev/mmcblk0p3 rw rootwait
        fdtdir ../
~~~
