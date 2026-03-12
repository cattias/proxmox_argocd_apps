echo "kiki ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/kiki
sudo chmod 0440 /etc/sudoers.d/kiki

sudo swapoff -a
sudo sed -i '/swap/ s/^/#/' /etc/fstab

sudo apt update && sudo apt install -y cloud-init qemu-guest-agent && sudo apt upgrade -y
# sudo systemctl enable --now qemu-guest-agent

sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv

# set healthchecks
# see specific script

# on the workers
kubectl label node k0s-worker-01 topology.kubernetes.io/region=pvemaster
kubectl label node k0s-worker-01 topology.kubernetes.io/zone=pvemaster
kubectl label node k0s-worker-02 topology.kubernetes.io/region=pvemaster
kubectl label node k0s-worker-02 topology.kubernetes.io/zone=pvemaster
kubectl label node k0s-worker-03 topology.kubernetes.io/region=pvemaster
kubectl label node k0s-worker-03 topology.kubernetes.io/zone=pvemaster

curl -fsSL https://tailscale.com/install.sh | sh
# Workers
sudo tailscale up --login-server=https://tailscale.attias.io --accept-dns=false --accept-routes=false
# Masters
sudo tailscale up --login-server=https://tailscale.attias.io --accept-dns=false --accept-routes=false --advertise-routes=192.168.178.0/24
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


sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-tailscale.conf
echo "net.ipv6.conf.all.forwarding = 1" | sudo tee -a /etc/sysctl.d/99-tailscale.conf

SERVICE_FILE="/etc/systemd/system/tailscale-eth-tuning.service"
cat <<EOF | sudo tee $SERVICE_FILE > /dev/null
[Unit]
Description=Tailscale Ethtool UDP GRO Tuning
After=network.target
# Ensure it waits for the specific device (replace ens18 if different)
Requires=sys-subsystem-net-devices-ens18.device
After=sys-subsystem-net-devices-ens18.device

[Service]
Type=oneshot
ExecStart=/usr/sbin/ethtool -K ens18 rx-udp-gro-forwarding on rx-gro-list off
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to see the new file
sudo systemctl daemon-reload
# Enable the service for future boots
sudo systemctl enable tailscale-eth-tuning.service
# Start it now to apply the settings immediately
sudo systemctl start tailscale-eth-tuning.service
