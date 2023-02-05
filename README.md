# Docker Virtual Raspberry Pi

Simple demo that runs a virtual Raspberry Pi 3B+ in a docker container using QEMU. Git lfs is used for lage files.

<div align="center">
	<img height="500" src="figure.png">
</div>

## QEMU

- Raspberry 3B+
- Cortex-A53 CPU
- 1GB RAM
- USB-Net

## Image

- Operating System: Raspberry Pi OS Lite 
- Release Date: 2022-09-06
- System: 64-bit
- Timezone: Europe/Berlin
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

## Credits and Additional Links 

- https://www.qemu.org/docs/master/system/arm/raspi.html
- https://github.com/lukechilds/dockerpi
- https://github.com/dhruvvyas90/qemu-rpi-kernel
- https://github.com/tianon/docker-qemu
- https://github.com/Drewsif/PiShrink

## Notes 

### Build and Start VPI

```shell
docker build -t vpi . && docker run --rm -it -p 5022:5022 --name vpi vpi
```

### Shrink Image
```shell
wget https://raw.githubusercontent.com/Drewsif/PiShrink/master/pishrink.sh
chmod +x pishrink.sh
sudo mv pishrink.sh /usr/local/bin/pishrink

sudo pishrink -Z raspios.img raspios.img.xz
```

### Create Image from SD Card

```shell
sudo dd bs=4M if=/dev/mmcblk0 of=raspios.img
```