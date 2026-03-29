echo "kiki ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/kiki
sudo chmod 0440 /etc/sudoers.d/kiki

sudo swapoff -a
sudo sed -i '/swap/ s/^/#/' /etc/fstab

sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv

sudo apt update && sudo apt install -y cloud-init qemu-guest-agent && sudo apt upgrade -y

# set healthchecks
# see specific script

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
ExecStart=/usr/bin/curl -sSf -m 20 --retry 5 https://hc.attias.io/ping/71919fb7-e209-4f95-87ee-a5a21c6b44ab
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

curl -fsSL https://tailscale.com/install.sh | sh
# Workers
sudo tailscale up --login-server=https://tailscale.attias.io --accept-dns=false --accept-routes=false
# All
sudo tailscale set --auto-update=true

# Glances web
sudo apt install pipx -y
sudo pipx ensurepath
sudo pipx install "glances[web]"

SERVICE_FILE="/usr/lib/systemd/system/glancesweb.service"
cat <<EOF | sudo tee $SERVICE_FILE > /dev/null
[Unit]
Description = Glances in Web Server Mode
After = network.target

[Service]
ExecStart = /root/.local/bin/glances  -w  -t  5

[Install]
WantedBy = multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl start glancesweb
sudo systemctl enable glancesweb

sudo reboot
