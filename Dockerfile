FROM debian:trixie-slim

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      qemu-system-arm qemu-utils \
      ca-certificates curl xz-utils \
      device-tree-compiler fdisk mtools openssh-client openssl \
 && rm -rf /var/lib/apt/lists/*

# Raspberry Pi OS Lite (64-bit). Override both args to use another release;
# leave RASPIOS_SHA256 empty to trust the .sha256 published next to the image.
ARG RASPIOS_URL=https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2026-10-06/2026-10-06-raspios-trixie-arm64-lite.img.xz
ARG RASPIOS_SHA256=483db18a48da399b5b7022ffae9a07bc6d99daab30e593aedac09b69ff422843

WORKDIR /vpi
RUN curl -fSL -o raspios.img.xz "${RASPIOS_URL}" \
 && SHA="${RASPIOS_SHA256:-$(curl -fsSL "${RASPIOS_URL}.sha256" | cut -d' ' -f1)}" \
 && echo "${SHA}  raspios.img.xz" | sha256sum -c -

COPY entrypoint.sh /entrypoint.sh

VOLUME /data
EXPOSE 5022
ENTRYPOINT ["/entrypoint.sh"]
