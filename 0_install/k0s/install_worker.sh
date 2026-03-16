echo "kiki ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/kiki
sudo chmod 0440 /etc/sudoers.d/kiki

sudo swapoff -a
sudo sed -i '/swap/ s/^/#/' /etc/fstab

sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv

sudo apt update && sudo apt install -y cloud-init qemu-guest-agent && sudo apt upgrade -y

# set healthchecks
# see specific script

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

# add to k0sctl config

kubectl label node k0s-worker-xx topology.kubernetes.io/region=pvemaster
kubectl label node k0s-worker-xx topology.kubernetes.io/zone=pvemaster
