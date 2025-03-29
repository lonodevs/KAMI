#!/bin/bash

hostnamectl set-hostname HQ-SRV.au-team.ipro; exec bash

cat <<EOF > /etc/net/ifaces/ens18/options
TYPE=eth
DISABLED=no
NM_CONTROLLED=no
BOOTPROTO=static
IPV4_CONFIG=yes
EOF

touch /etc/net/ifaces/ens18/ipv4address
cat <<EOF > /etc/net/ifaces/ens18/ipv4address
192.168.1.62/26
EOF

touch /etc/net/ifaces/ens18/ipv4route
cat <<EOF > /etc/net/ifaces/ens18/ipv4route
default via 192.168.1.1
EOF

cat <<EOF > /etc/resolv.conf
nameserver 8.8.8.8
nameserver 77.88.8.8
EOF

useradd sshuser -u 1010
echo "sshuser:P@ssw0rd" | chpasswd
usermod -aG wheel sshuser

touch /etc/sudoers
cat <<EOF /etc/sudoers
sshuser ALL=(ALL) NOPASSWD:ALL
EOF

sed -i 's/#Port 22/Port 2024/Ig' /etc/openssh/sshd_config
sed -i 's/#MaxAuthTries 6/MaxAuthTries 2/Ig' /etc/openssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/Ig' /etc/openssh/sshd_config
sed -i 's/#Banner none/Banner /etc/openssh/bannermotd/Ig' /etc/openssh/sshd_config
echo "AllowUsers sshuser" | tee -a /etc/openssh/sshd_config

touch /etc/openssh/bannermotd
cat <<EOF /etc/openssh/bannermotd
----------------------
Authorized access only
----------------------
EOF

systemctl restart sshd

# Identify available disks (assuming 3 disks are available)
DISKS=($(lsblk -d -o NAME -n | grep -v "md0" | grep -E "^sd[b-d]$"))

# Check if we have exactly 3 disks
if [ ${#DISKS[@]} -ne 3 ]; then
    echo "Error: Expected 3 disks (sdb, sdc, sdd), found ${#DISKS[@]}"
    exit 1
fi

# Prepare disks for RAID
echo "Preparing disks for RAID 5"
for disk in "${DISKS[@]}"; do
    mdadm --zero-superblock --force /dev/$disk
    wipefs --all --force /dev/$disk
done

# Create RAID 5 array
echo "Creating RAID 5 array /dev/md0"
mdadm --create /dev/md0 --level=5 --raid-devices=3 /dev/sd{b,c,d}
if [ $? -ne 0 ]; then
    echo "Error creating RAID array"
    exit 1
fi

# Create filesystem
echo "Creating ext4 filesystem on /dev/md0"
mkfs -t ext4 /dev/md0

# Configure mdadm
echo "Configuring mdadm"
mkdir -p /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf

# Create mount point and mount RAID
echo "Creating /raid5 directory and mounting RAID"
mkdir -p /raid5
echo "/dev/md0  /raid5  ext4  defaults  0  0" >> /etc/fstab
mount -a

# Verify mount
df -h | grep /dev/md0

# Configure NFS Server
echo "Configuring NFS Server"

# Install NFS packages
apt-get update
apt-get install -y nfs-kernel-server

# Create NFS share directory
mkdir -p /raid5/nfs
chmod 766 /raid5/nfs

# Configure exports
echo "/raid5/nfs 192.168.2.0/28(rw,no_root_squash,no_subtree_check)" > /etc/exports

# Apply NFS settings
exportfs -arv
systemctl enable --now nfs-server

echo "HQ-SRV configuration complete"
echo "RAID 5 created: /dev/md0 mounted at /raid5"
echo "NFS share: /raid5/nfs available to 192.168.2.0/28"

# HQ-CLI Configuration (NFS Client)
echo ""
echo "Configuring HQ-CLI (NFS Client)"


