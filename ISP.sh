#!/bin/bash

mkdir /etc/net/ifaces/ens19
mkdir /etc/net/ifaces/ens20

touch /etc/net/ifaces/ens19/options
touch /etc/net/ifaces/ens20/options

cat <<EOF > /etc/net/ifaces/ens19/options
TYPE=eth
DISABLED=no
NM_CONTROLLED=no
BOOTPROTO=static
IPV4_CONFIG=yes
EOF

cat <<EOF > /etc/net/ifaces/ens20/options
TYPE=eth
DISABLED=no
NM_CONTROLLED=no
BOOTPROTO=static
IPV4_CONFIG=yes
EOF

cat <<EOF > /etc/net/ifaces/ens19/ipv4address
172.16.4.1/28
EOF

cat <<EOF > /etc/net/ifaces/ens20/ipv4address
172.16.5.1/28
EOF


sed -i 's/net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/net/sysctl.conf


apt-get update && apt-get install -y firewalld 
systemctl enable --now firewalld
firewall-cmd --permanent --zone=public --add-interface=ens18
firewall-cmd --permanent --zone=trusted --add-interface=ens19
firewall-cmd --permanent --zone=trusted --add-interface=ens20
firewall-cmd --permanent --zone=public --add-masquerade
firewall-cmd --reload
systemctl restart firewalld
systemctl restart network

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
