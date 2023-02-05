#!/bin/sh
set -e

cd /vpi

# tar xvf raspios.img.tar.gz raspios.img

qemu-img resize -f raw raspios.img 8G

exec qemu-system-aarch64 \
  -machine raspi3b \
  -cpu cortex-a53 \
  -m 1024m \
  -drive "format=raw,file=raspios.img" \
  -netdev user,id=net0,hostfwd=tcp::5022-:22 \
  -device usb-net,netdev=net0 \
  -dtb bcm2710-rpi-3-b-plus.dtb \
  -kernel kernel8.img \
  -append "rw earlyprintk loglevel=8 console=ttyAMA0,115200 dwc_otg.lpm_enable=0 root=/dev/mmcblk0p2 rootwait panic=1 dwc_otg.fiq_fsm_enable=0" \
  -display none \
  -serial mon:stdio
