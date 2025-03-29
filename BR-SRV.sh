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

# Создание пользователя sshuser с паролем P@ssw0rd
echo "Creating sshuser with password P@ssw0rd"
useradd -m -s /bin/bash sshuser
echo "sshuser:P@ssw0rd" | chpasswd

# Добавление пользователя в группу sudo (если нужно)
usermod -aG sudo sshuser

# Настройка SSH-доступа
echo "Configuring SSH access"

# Резервное копирование конфига SSH
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Разрешить аутентификацию по паролю (если нужно)
sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Разрешить вход для sshuser
if ! grep -q "AllowUsers sshuser" /etc/ssh/sshd_config; then
    echo "AllowUsers sshuser" >> /etc/ssh/sshd_config
fi

# Перезапуск SSH сервера
systemctl restart sshd

# Информация для подключения
echo "SSH access configured:"
echo "Username: sshuser"
echo "Password: P@ssw0rd"
echo "You can now connect using: ssh sshuser@$(hostname -I | awk '{print $1}')"

# Дополнительные настройки безопасности (опционально)
# Установка сроков действия пароля
chage -M 90 sshuser
# Запрет пустых паролей
sed -i 's/^PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config


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
