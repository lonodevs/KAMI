#!/bin/bash

#Переименование виртуалки
hostnamectl set-hostname BR-SRV.au-team.ipro; exec bash

#Настройка интерфейсов и времени
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

#Создание пользователя sshuser и настройка sshd конфига
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

touch /etc/openssh/bannermotd
cat <<EOF /etc/openssh/bannermotd
----------------------
Authorized access only
----------------------
EOF
systemctl restart sshd

#Создание NTP
apt-get install chrony -y 
sed -i '3i#pool pool.ntp.org iburst' /etc/chrony.conf
systemctl enable --now chronyd

cat <<EOF >> /etc/resolv.conf 
nameserver 8.8.8.8
EOF

#Создание Samba DC
apt-get update && apt-get install -y task-samba-dc bind 
control bind-chroot disabled
grep -q KRB5RCACHETYPE /etc/sysconfig/bind || echo 'KRB5RCACHETYPE="none"' >> /etc/sysconfig/bind
systemctl stop bind
rm -f /etc/samba/smb.conf
rm -rf /var/lib/samba
rm -rf /var/cache/samba
mkdir -p /var/lib/samba/sysvol
samba-tool domain provision --realm=au-team.irpo --domain=au-team --adminpass='P@ssw0rd' --dns-backend=SAMBA_INTERNAL --server-role=dc --use-rfc2307

#Настройка Ansible
apt-get install -y ansible sshpass

sed -i 's/#inventory = /etc/ansible/hosts / #inventory = ./inventory.yml/Ig /etc/ansible/ansible.cfg
sed -i 's/#host_key_checking = True/host_key_checking = False/Ig /etc/ansible/ansible.cfg

cat <<EOF >> /etc/ansible/inventory.yml
 all:
  children:
    Networking:
      hosts:
        hq-rtr:
        br-rtr:
    Servers:
      hosts:
        hq-srv:
          ansible_host: 192.168.100.62
          ansible_port: 2024
    Clients:
      hosts:
        hq-cli:
          ansible_host: 192.168.200.14
          ansible_port: 2024
EOF

cd /etc/ansible
mkdir group_vars
touch group_vars/{all.yml,Networking.yml}

cat <<EOF >> /etc/ansible/group_vars/all.yml
ansible_ssh_user: sshuser
ansible_ssh_pass: P@ssw0rd
ansible_python_interpreter: /usr/bin/python3
EOF

cat <<EOF >> /etc/ansible/group_vars/Networking.yml

ansible_connection: network_cli
ansible_network_os: ios
EOF

#Установка Docker 
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
