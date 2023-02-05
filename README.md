# Docker Virtual PI

Simple demo that runs a Raspberry PI 3B+ in a docker container using QEMU.

![Docker Virtual PI Demo](figure.png)

## Qemu

- Raspberry 3B+
- 1GB RAM
- Cortex-A53 CPU
- USB-Net

## Image

- Operating System: Raspberry Pi OS Lite 
- Release Date: 2022-09-22 
- System: 64-bit
- Kernel Version: 5.15
- Debian Version: 11 (bullseye)
- SHA256 Integrity Hash: `72c773781a0a57160eb3fa8bb2a927642fe60c3af62bc980827057bcecb7b98b`
- SSH: Enabled
- Password Authentication: Enabled 
- Hostname: `rapsberrypi`
- Username: `pi`
- Password: `raspberry`
- Disk Size: 8GB
- Latest APT Update and Upgrade: 2023-02-05
- Additional Tools: `tree`, `jq`, `net-tools`, `git`, `stress`, `nmap`, `node`.

## Known Issues

- disk size is fixed to 8gb
- internet connection is slow

## Credits and additional Links 

- https://www.qemu.org/docs/master/system/arm/raspi.html
- https://github.com/lukechilds/dockerpi
- https://github.com/dhruvvyas90/qemu-rpi-kernel
- https://github.com/tianon/docker-qemu
- https://github.com/Drewsif/PiShrink

## Notes 

### Build and Start VPI

```
docker build -t vpi . && docker run --rm -it -p 5022:5022 --name vpi vpi
```

### Resize Image
```
qemu-resize raspios.img 8G
```

### Shrink Image
```
wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh
chmod +x pishrink.sh
sudo mv pishrink.sh /usr/local/bin

sudo pishrink.sh -Z raspios.img
```

### Create Image from SD Card

```
sudo dd bs=4M if=/dev/mmcblk0 of=raspios.img
```