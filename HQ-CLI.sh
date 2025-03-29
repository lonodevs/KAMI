
hostnamectl set-hostname HQ-CLI.au-team.ipro; exec bash

# Install NFS client packages
apt-get update
apt-get install -y nfs-common

# Create mount point
mkdir -p /mnt/nfs
chmod 777 /mnt/nfs

# Add to fstab (assuming HQ-SRV IP is 192.168.1.10)
echo "192.168.1.10:/raid5/nfs  /mnt/nfs  nfs  defaults  0  0" >> /etc/fstab

# Mount NFS share
mount -a

# Verify mount
df -h | grep nfs

echo "HQ-CLI configuration complete"
echo "NFS share mounted at /mnt/nfs"
echo "Готово!"
echo "RAID 5 создан на /dev/md0 и смонтирован в /mnt/raid5"
echo "NFS-сервер настроен и экспортирует /mnt/raid5/nfs"
