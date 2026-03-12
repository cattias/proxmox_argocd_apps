apt update && apt install radosgw -y
[client.rgw.pvemaster]
host = pvemaster
keyring = /etc/pve/priv/ceph.client.rgw.pvemaster.keyring
log file = /var/log/ceph/client.rgw.pvemaster.log
rgw_frontends = "beast port=7480"

# Create the auth key
ceph auth get-or-create client.rgw.pvemaster osd 'allow rwx' mon 'allow rw' -o /etc/pve/priv/ceph.client.rgw.pvemaster.keyring

# Start the service
systemctl enable ceph-radosgw@rgw.pvemaster
systemctl start ceph-radosgw@rgw.pvemaster

ceph osd pool set default.rgw.meta min_size 1
ceph osd pool set default.rgw.meta size 2
ceph osd pool set default.rgw.meta crush_rule local-storage

ceph osd lspools

bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/glances.sh)"
