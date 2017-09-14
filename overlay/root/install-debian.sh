#!/bin/sh

exec 6>&1 > install-debian.log 2>&1
print () {
	printf "$@" >&6
}
set -ex

print "THIS COMMAND WILL REPLACE EVERYTHING ON INTERNAL STORAGE\n"
print "Press RETURN to continue, press ^C to abort\n"
read dummy

# First we must install any packages that are needed by the installer
# (but are not included in the developer image).
print "Preparing environment ..."
dpkg -i extra-packages/*.deb
print " done\n"

print "Installing bootloader .."
dd if=/boot/fastboot.bin of=/dev/mmcblk0
sfdisk /dev/mmcblk0 <<EOF
label: dos
device: /dev/mmcblk0
unit: sectors

/dev/mmcblk0p1 : start=           1, size=        8191, type=f0
/dev/mmcblk0p2 : start=        8192, size=      279336, type=c, bootable
/dev/mmcblk0p3 : start=      288768, size=    14981120, type=83
EOF
print .
sleep 3				# Allow time to update nodes in /dev
print " done\n"

print "Creating rootfs (this may take a long time) ..."
mkfs.ext4 -q -L rootfs /dev/mmcblk0p3
mkdir -p /sysimage
mount /dev/mmcblk0p3 /sysimage
print " done\n"

# Unpack the rootfs (with progress meter)
cd /sysimage
gunzip -c /root/snapshots.linaro.org/debian/images/stretch/developer-arm64/latest/linaro-stretch-*.tar.gz | tar xvf - | \
	awk '{ i++; if (i%23==0) printf("\rUnpacking rootfs ... %d files", i); fflush()} END { printf("\rUnpacking rootfs ... %d files\n", i); }' >&6
mv binary/* .
rmdir binary

print "Creating boot image .."
mkfs.vfat -F 32 -n boot /dev/mmcblk0p2
mkdir -p /sysimage/boot
mount /dev/mmcblk0p2 /sysimage/boot
print .
print " done\n"

print "Finalizing image ."
tar -C / -cf - boot lib/modules | tar -C /sysimage -xf -
tar -C /root/overlay-debian -cf - . | tar -C /sysimage -xf -
print .
umount /sysimage/boot
print .
cd /
umount /sysimage
print .
sync
print " done\n"

print "\nPlease remove the install media and press RESET\n"
