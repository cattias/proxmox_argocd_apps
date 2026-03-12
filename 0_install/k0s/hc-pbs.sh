#!/bin/bash

# Define the file path
SERVICE_FILE="/etc/systemd/system/healthcheck-ping.service"
TIMER_FILE="/etc/systemd/system/healthcheck-ping.timer"

echo "Creating systemd service at $SERVICE_FILE..."

# Use cat and tee to write the multiline content to a protected file
cat <<EOF | tee $SERVICE_FILE > /dev/null
[Unit]
Description=Ping Healthchecks.io
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/curl -sSf -m 20 --retry 5 https://hc.attias.io/ping/20f90f48-12a6-4513-a803-d7ed1d1abcb5
EOF

echo "Creating systemd timer at $TIMER_FILE..."

# Use cat and tee to write the multiline content to a protected file
cat <<EOF | tee $TIMER_FILE > /dev/null
[Unit]
Description=Run Healthcheck Ping every minute

[Timer]
# Run 1 minute after boot
OnBootSec=1min
# Run every 1 minute thereafter
OnUnitActiveSec=1min
# Add a little "random" delay so both nodes don't hit the server at the exact same microsecond
RandomizedDelaySec=5

[Install]
WantedBy=timers.target
EOF

# Reload systemd to recognize the new service
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Enable the timer so it starts on boot
systemctl enable healthcheck-ping.timer

# Start it now
systemctl start healthcheck-ping.timer

echo "Done!"