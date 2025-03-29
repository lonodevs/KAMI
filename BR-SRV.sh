#!/bin/bash


cat <<EOF > /etc/net/ifaces/ens18/options
TYPE=eth
DISABLED=no
NM_CONTROLLED=no
BOOTPROTO=static
IPV4_CONFIG=yes
EOF

touch /etc/net/ifaces/ens18/ipv4address
cat <<EOF > /etc/net/ifaces/ens18/ipv4address
192.168.0.30/27
EOF

timedatectl set-timezone Europe/Samara
timedatectl status

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

apt-get update
apt-get install -y chrony

# Backup original config
echo "Backing up original chrony configuration..."
cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak

# Configure Chrony as local NTP server
echo "Configuring /etc/chrony/chrony.conf..."
cat > /etc/chrony/chrony.conf << 'EOL'
server 127.0.0.1 iburst prefer
hwtimestamp *
local stratum 5
allow 0/0

# Logging configuration
logdir /var/log/chrony
log measurements statistics tracking

# Key file configuration
keyfile /etc/chrony/chrony.keys

# Command socket
commandkey 1
generatecommandkey

# This directive sets the maximum interval between clock updates
maxupdateskew 100.0

# Step the system clock if the adjustment is larger than 1 second
makestep 1.0 3
EOL

# Restart Chrony service
systemctl restart chronyd
systemctl enable chronyd

# Verify configuration
echo "Current time sources:"
chronyc sources

echo "Current stratum level:"
chronyc tracking | grep Stratum

echo "NTP server status:"
systemctl status chronyd --no-pager


systemctl disable —now ahttpd
apt-get install -y docker-{ce,compose}
systemctl enable --now docker

touch /home/sshuser/wiki.yaml
cat <<EOF > /home/sshuser/wiki.yaml
services:
  mediawiki:
    container_name: wiki
    image: mediawiki
    restart: always
    ports:
      - "8080:80"
    links:
      - db
#    volumes:
#      - ./LocalSettings.php:/var/www/html/LocalSettings.php

  db:
    container_name: mariadb
    image: mariadb
    restart: always
    environment:
      MARIADB_DATABASE: mediawiki
      MARIADB_USER: wiki
      MARIADB_PASSWORD: WikiP@ssw0rd
      MARIADB_ROOT_PASSWORD: P@ssw0rd
    volumes:
      - db_data:/var/lib/mysql

volumes:
  db_data:
EOF
