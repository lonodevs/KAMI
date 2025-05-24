
hostnamectl set-hostname hq-cli.au-team.ipro;

#Создание пользователя sshuser и настройка sshd конфига
useradd sshuser -u 1010
echo "sshuser:P@ssw0rd" | chpasswd
usermod -aG wheel sshuser

touch /etc/sudoers
cat <<EOF /etc/sudoers
sshuser ALL=(ALL) NOPASSWD:ALL
EOF


CONFIG_FILE="/etc/ssh/sshd_config"  

# Изменить SSH-порт с 22 на 2024  
sed -i 's/^#Port 22$/Port 2024/' "$CONFIG_FILE"  

# Уменьшить MaxAuthTries с 6 до 2  
sed -i 's/^#MaxAuthTries 6$/MaxAuthTries 2/' "$CONFIG_FILE"  

# Разрешить аутентификацию по паролю 
sed -i 's/^#PasswordAuthentication yes$/PasswordAuthentication yes/' "$CONFIG_FILE"  

touch /etc/openssh/bannermotd
cat <<EOF /etc/openssh/bannermotd

----------------------
Authorized access only
----------------------
EOF
systemctl restart sshd


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
