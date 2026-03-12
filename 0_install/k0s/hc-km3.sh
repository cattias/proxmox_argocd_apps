#!/bin/bash

# Define the file path
SERVICE_FILE="/etc/systemd/system/healthcheck-ping.service"
TIMER_FILE="/etc/systemd/system/healthcheck-ping.timer"

echo "Creating systemd service at $SERVICE_FILE..."

# Use cat and sudo tee to write the multiline content to a protected file
cat <<EOF | sudo tee $SERVICE_FILE > /dev/null
[Unit]
Description=Ping Healthchecks.io
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/curl -sSf -m 20 --retry 5 https://hc.attias.io/ping/0b8fbd1b-b994-4e1a-b977-1524c4852ec9
EOF

echo "Creating systemd timer at $TIMER_FILE..."

# Use cat and sudo tee to write the multiline content to a protected file
cat <<EOF | sudo tee $TIMER_FILE > /dev/null
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
sudo systemctl daemon-reload

# Enable the timer so it starts on boot
sudo systemctl enable healthcheck-ping.timer

# Start it now
sudo systemctl start healthcheck-ping.timer

echo "Done!"