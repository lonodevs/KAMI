#!/bin/bash
Имя и время
СУС 1.1
hostnamectl set-hostname hq-cli.au-team.irpo;
apt-get install -y tzdata
timedatectl set-timezone Europe/Samara

Юзер
useradd sshuser -u 1015
echo "sshuser:P@ssw0rd" | chpasswd
usermod -aG wheel sshuser

touch /etc/sudoers
vim /etc/sudoers
sshuser ALL=(ALL) NOPASSWD:ALL

Домен
echo "default_realm = AU-TEAM.IRPO" | sudo tee -a /etc/krb5.conf
echo "nameserver 192.168.24.14" | sudo tee -a /etc/resolv.conf

apt-get update && apt-get install -y gpupdate
gpupdate-setup enable
apt-get install -y admc
apt-get install -y gpui
apt-get install -y libnss-role
control libnss-role
roleadd hq wheel
rolelst
apt-get install -y admx-*
admx-msi-setup
Зайди на суса 2.1

NFS
apt-get update && apt-get install -y nfs-{utils,clients}
mkdir /mnt/nfs 
chmod 777 /mnt/nfs 
vim /etc/fstab
192.168.18.30:/raid5/nfs /mnt/nfs nfs defaults 0 0
mount -av
df -h
