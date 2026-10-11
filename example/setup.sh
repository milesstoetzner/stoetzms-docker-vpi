#!/bin/sh
# Runs once as root on the Pi's first boot, from /boot/firmware/setup
set -eu

install -m 755 server.py /usr/local/bin/hello-server

cat > /etc/systemd/system/hello-server.service <<'EOF'
[Unit]
Description=Example web server
After=network-online.target

[Service]
ExecStart=/usr/local/bin/hello-server
DynamicUser=yes
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now hello-server
