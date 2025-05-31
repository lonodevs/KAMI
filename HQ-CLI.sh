#!/bin/bash

hostnamectl set-hostname hq-cli.au-team.irpo;

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


echo "Allow users = sshuser" >> "$CONFIG_FILE" 

# Разрешить аутентификацию по паролю 
sed -i 's/^#PasswordAuthentication yes$/PasswordAuthentication yes/' "$CONFIG_FILE"  

touch /etc/openssh/banner
cat <<EOF /etc/openssh/banner

----------------------
Authorized access only
----------------------
EOF
systemctl restart sshd

echo "default_realm = AU-TEAM.IRPO" | sudo tee -a /etc/krb5.conf
echo "nameserver 192.168.0.30" | sudo tee -a /etc/resolv.conf

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
