#!/bin/sh
set -eu

IMG=/data/raspios.img
KEY=/data/shutdown_key
BOOT=/tmp/boot
DISK_SIZE="${DISK_SIZE:-8G}"
PI_HOSTNAME="${PI_HOSTNAME:-raspberrypi}"
PI_PASSWORD="${PI_PASSWORD:-raspberry}"
SSH_PUBLIC_KEY="${SSH_PUBLIC_KEY:-}"
PORTS="${PORTS:-}"

# Point mtools drive b: at the FAT boot partition (partition 1) of an image
use_boot_partition() {
  start=$(sfdisk -d "$1" | sed -n 's/^.*1 : start= *\([0-9]*\),.*$/\1/p')
  export MTOOLSRC=/tmp/mtoolsrc
  printf 'mtools_skip_check=1\ndrive b: file="%s" offset=%s\n' "$1" "$((start * 512))" > "$MTOOLSRC"
}

# First start: unpack the image, grow it and seed cloud-init
if [ ! -f "$IMG" ]; then
  echo "Preparing $IMG (first start) ..."
  mkdir -p /data
  xz -dc /vpi/raspios.img.xz > "$IMG.tmp"
  # QEMU requires the SD card size to be a power of 2; the root partition is
  # grown to fill it by the guest's initramfs on first boot
  qemu-img resize -q -f raw "$IMG.tmp" "$DISK_SIZE"

  # Key the container uses to shut the Pi down cleanly on docker stop
  rm -f "$KEY" "$KEY.pub"
  ssh-keygen -q -t ed25519 -N '' -C vpi-shutdown -f "$KEY"

  use_boot_partition "$IMG.tmp"
  # cloud-init (the way Raspberry Pi Imager does it): user, hostname, SSH key,
  # and DHCP on the USB NIC, which Raspberry Pi OS otherwise treats as a USB
  # gadget link with only a link-local address
  {
    echo "#cloud-config"
    echo "hostname: $PI_HOSTNAME"
    echo "users:"
    echo "  - name: pi"
    echo "    lock_passwd: false"
    echo "    hashed_passwd: '$(openssl passwd -6 "$PI_PASSWORD")'"
    echo "    sudo: ALL=(ALL) NOPASSWD:ALL"
    echo "    ssh_authorized_keys:"
    echo "      - $(cat "$KEY.pub")"
    if [ -n "$SSH_PUBLIC_KEY" ]; then
      echo "      - $SSH_PUBLIC_KEY"
    fi
    if [ -f /vpi/setup/setup.sh ]; then
      echo "runcmd:"
      echo "  - [sh, -c, 'cd /boot/firmware/setup && sh setup.sh && sync']"
    fi
  } > /tmp/user-data
  printf 'network:\n  version: 2\n  ethernets:\n    usb0:\n      dhcp4: true\n' > /tmp/network-config
  # An empty ssh file enables the SSH server
  : > /tmp/ssh
  mcopy -o /tmp/user-data /tmp/network-config /tmp/ssh b:/
  # Images built FROM this one put files into /vpi/setup; they land in
  # /boot/firmware/setup and setup.sh runs once as root on first boot
  if [ -d /vpi/setup ]; then
    mcopy -o -s /vpi/setup b:/
  fi

  mv "$IMG.tmp" "$IMG"
fi

# Forward container ports to the Pi: SSH on 5022, plus PORTS, a list of
# "port" or "container_port:pi_port" (e.g. "8080 3000:80")
NETDEV="user,id=net0,hostfwd=tcp::5022-:22"
for p in $(echo "$PORTS" | tr ',' ' '); do
  NETDEV="$NETDEV,hostfwd=tcp::${p%%:*}-:${p##*:}"
done

# docker stop: shut the Pi down cleanly, so recent writes are not lost; only
# cut the power if that fails. Allow enough time, e.g. docker stop -t 60.
shutdown_pi() {
  echo "Shutting down the Pi ..."
  ssh -n -i "$KEY" -p 5022 -o BatchMode=yes -o ConnectTimeout=5 \
    -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR \
    pi@127.0.0.1 sudo systemctl poweroff --no-block || kill -TERM "$QEMU_PID"
  wait "$QEMU_PID"
  exit 0
}
trap shutdown_pi TERM INT
exec 3<&0

# Like a real Pi, read kernel, initramfs, dtb and cmdline from the image's own
# boot partition on every (re)boot, so the guest's changes to them apply: the
# first boot resizes the root partition, changes the PARTUUID and rewrites
# cmdline.txt, and apt upgrades the kernel
use_boot_partition "$IMG"
mkdir -p "$BOOT"
while :; do
  mcopy -o -n b:/kernel8.img b:/initramfs8 b:/bcm2710-rpi-3-b-plus.dtb b:/cmdline.txt "$BOOT"
  # Like dtoverlay=disable-bt: free the PL011 from Bluetooth, so it is a
  # regular tty and the serial console gets a login prompt
  fdtput -r "$BOOT/bcm2710-rpi-3-b-plus.dtb" /soc/serial@7e201000/bluetooth 2>/dev/null || true

  # The firmware normally resolves serial0; under QEMU the PL011 is ttyAMA1.
  # QEMU's BCM2835 watchdog resets the machine as soon as it is armed, so keep
  # the initramfs and systemd from arming it.
  CMDLINE="$(sed -e 's/console=serial0/console=ttyAMA1/' -e 's/ *console=tty1//' "$BOOT/cmdline.txt" | tr -d '\r\n')"
  CMDLINE="$CMDLINE watchdog_disarm=0 systemd.watchdog_sec=off dwc_otg.lpm_enable=0 dwc_otg.fiq_fsm_enable=0"

  qemu-system-aarch64 \
    -machine raspi3b \
    -cpu cortex-a53 \
    -m 1G \
    -drive "if=sd,format=raw,file=$IMG" \
    -kernel "$BOOT/kernel8.img" \
    -initrd "$BOOT/initramfs8" \
    -dtb "$BOOT/bcm2710-rpi-3-b-plus.dtb" \
    -append "$CMDLINE" \
    -netdev "$NETDEV" \
    -device usb-net,netdev=net0 \
    -display none \
    -no-reboot \
    -serial mon:stdio <&3 &
  QEMU_PID=$!
  wait "$QEMU_PID" || exit $?
  echo "Pi rebooted, restarting QEMU ..."
done
