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
