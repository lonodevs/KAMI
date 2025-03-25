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
#!/bin/bash

# Установка Chrony
echo "Устанавливаем chrony..."
apt-get update
apt-get install -y chrony

# Резервное копирование текущего конфига
echo "Создаем backup конфигурации..."
cp /etc/chrony/chrony.conf /etc/chrony/chrony.conf.bak

# Настройка Chrony как NTP-сервера
echo "Настраиваем /etc/chrony/chrony.conf..."
cat > /etc/chrony/chrony.conf << 'EOF'
# Настройки сервера
server 127.0.0.1 iburst prefer
hwtimestamp *
local stratum 5
allow 0/0

# Дополнительные настройки
keyfile /etc/chrony/chrony.keys
driftfile /var/lib/chrony/chrony.drift
logdir /var/log/chrony
maxupdateskew 100.0
makestep 1.0 3
rtcsync
EOF

# Перезапуск службы
echo "Перезапускаем chronyd..."
systemctl restart chronyd
systemctl enable chronyd

# Проверка работы
echo -e "\nПроверка конфигурации:"
echo "1. Источники времени:"
chronyc sources

echo -e "\n2. Уровень стратума:"
chronyc tracking | grep Stratum

echo -e "\n3. Состояние службы:"
systemctl status chronyd --no-pager -l

# Настройка клиента (информация для настройки EcoRouter)
echo -e "\nДля настройки клиента EcoRouter используйте следующие параметры:"
echo "IP-адрес этого сервера: $(hostname -I | awk '{print $1}')"
echo "Команды для EcoRouter:"
echo "ntp server $(hostname -I | awk '{print $1}')"
echo "ntp timezone utc+5"

echo "show ntp status"



systemctl disable —now ahttpd
apt-get install -y docker-{ce,compose}
systemctl enable --now docker

touch wiki.yaml
cat <<EOF > wiki.yaml
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
