#! /bin/bash

BUSYBOX_VERSION="${BUSYBOX_VERSION:=1.37.0}"
LINUX_KERNEL_VERSION="${LINUX_KERNEL_VERSION:=6.12.56}"

set -e

apt update && apt install -y build-essential wget xz-utils cpio flex bison bc \
qemu-system  ncurses-dev libelf-dev libssl-dev

mkdir /build && cd /build

wget https://busybox.net/downloads/busybox-${BUSYBOX_VERSION}.tar.bz2
tar xvf busybox-${BUSYBOX_VERSION}.tar.bz2
cd busybox-${BUSYBOX_VERSION}

make defconfig

mkdir -p ../rootfs/{bin,sbin,etc,proc,sys,usr/{bin,sbin},dev,run,tmp,var}

make CONFIG_STATIC=y CONFIG_PREFIX=../rootfs install

cat << EOF > ../rootfs/init
#!/bin/sh
mount -t proc none /proc            
mount -t sysfs none /sys
mount -t tmpfs tmpfs /run
mount -t tmpfs tmpfs /tmp
mdev -s
if [ -c /dev/fb0 ]; then
  TTY=/dev/tty1
else
  TTY=/dev/ttyS0
fi
echo 0 > /proc/sys/kernel/printk
printf "\033c" > \$TTY
cat << INNER > \$TTY
                           /)
                  /\___/\ (( 
                  \ @_@'/  ))
                  {_:Y:.}_//
================{_}^-'{_}====================
~                                           ~ 
~    Welcome to ArtyomSoft Minimal Linux    ~
~                                           ~
=============================================

TTY: \$(basename \$TTY)
Time: \$(date)
Kernel version: \$(uname -r)
=============================================
INNER

exec setsid sh -c "exec sh <'\$TTY' >'\$TTY' 2>'\$TTY'"
#exec setsid sh <\$TTY >\$TTY 2>\$TTY

EOF


chmod +x ../rootfs/init

cd ../rootfs

find . | cpio -o -H newc | gzip > ../initramfs.cpio.gz

cd ..

wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${LINUX_KERNEL_VERSION}.tar.xz
tar xvf linux-${LINUX_KERNEL_VERSION}.tar.xz
cd linux-${LINUX_KERNEL_VERSION}

make tinyconfig

./scripts/config \
-e 64BIT \
-e PCI \
-e PCI_HOST_GENERIC \
-e TTY \
-e BLK_DEV_INITRD \
-e SERIAL_8250 \
-e SERIAL_8250_CONSOLE \
-e BINFMT_ELF \
-e BINFMT_MISC \
-e BINFMT_SCRIPT \
-e DEVTMPFS \
-e DEVTMPFS_MOUNT \
-e TMPFS \
-e PRINTK \
-e EARLY_PRINTK \
-e PRINTK_TIME \
-e PROC_FS \
-e SYSFS \
--set-str INITRAMFS_SOURCE "../initramfs.cpio.gz" \
-e RD_GZIP \
-e INITRAMFS_COMPRESSION_GZIP \
-e ACPI \
-e EFI \
-e EFI_STUB \
-e FB \
-e FB_EFI \
-e DRM \
-e VIRTIO_MENU \
-e DRM_VIRTIO_GPU \
-e DRM_VIRTIO_GPU_KMS \
-e FRAMEBUFFER_CONSOLE

make olddefconfig
make -j$(nproc)

mkdir -p /result/ESP/EFI/BOOT

cp arch/x86/boot/bzImage /result/ESP/EFI/BOOT/BOOTX64.EFI

cp /usr/share/OVMF/OVMF_VARS.fd /result/
cp /usr/share/OVMF/OVMF_CODE.fd /result/

qemu-system-x86_64 -m 4096m -kernel /result/ESP/EFI/BOOT/BOOTX64.EFI -append console=ttyS0 -nographic
