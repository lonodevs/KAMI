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
192.168.1.62/26
EOF

touch /etc/net/ifaces/ens18/ipv4route
cat <<EOF > /etc/net/ifaces/ens18/ipv4route
default via 192.168.1.1
EOF

cat <<EOF > /etc/resolv.conf
nameserver 8.8.8.8
nameserver 77.88.8.8
EOF

# Установка необходимых пакетов
apt-get update
apt-get install -y bind9 bind9-utils

# Настройка /etc/bind/options.conf
cat <<EOF > /etc/bind/options.conf
options {
    directory "/var/cache/bind";

    listen-on { 127.0.0.1; 192.168.1.62; };
    forwarders { 77.88.8.8; };
    allow-query { 192.168.1.0/26; 192.168.1.0/28; 192.168.0.0/27; };

    recursion yes;
    dnssec-validation auto;

    auth-nxdomain no;    # conform to RFC1035
    listen-on-v6 { any; };
};
EOF

# Генерация и настройка ключа rndc
rndc-confgen -a -k rndc-key
chown root:bind /etc/bind/rndc.key
chmod 640 /etc/bind/rndc.key

# Настройка /etc/bind/rndc.key
cat <<EOF > /etc/bind/rndc.key
key "rndc-key" {
    algorithm hmac-sha256;
    secret "$(grep secret /etc/bind/rndc.key | awk '{print $2}' | tr -d '";')";
};
EOF

# Проверка конфигурации
named-checkconf

# Запуск и добавление в автозагрузку BIND
systemctl enable --now named

# Настройка /etc/resolv.conf
cat <<EOF > /etc/resolv.conf
search au-team.irpo yandex.ru
nameserver 127.0.0.1
nameserver 192.168.1.62
nameserver 77.88.8.8
EOF

# Создание и настройка прямой зоны
mkdir -p /etc/bind/zones
cat <<EOF > /etc/bind/named.conf.local
zone "au-team.irpo" {
    type master;
    file "/etc/bind/zones/au-team.irpo.db";
};

zone "1.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/1.168.192.in-addr.arpa";
};

zone "1.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/1.168.192.in-addr.arpa";
};

zone "0.168.192.in-addr.arpa" {
    type master;
    file "/etc/bind/zones/0.168.192.in-addr.arpa";
};
EOF

# Создание файла прямой зоны
cat <<EOF > /etc/bind/zones/au-team.irpo.db
\$TTL    1D
@       IN      SOA     au-team.irpo. root.au-team.irpo. (
                                2024102200      ; serial
                                12H             ; refresh
                                1H              ; retry
                                1W              ; expire
                                1H              ; ncache
                        )
        IN      NS      au-team.irpo.
        IN      A       192.168.1.62
hq-rtr  IN      A       192.168.1.1
br-rtr  IN      A       192.168.0.1
hq-srv  IN      A       192.168.1.62
hq-cli  IN      A       192.168.1.14
br-srv  IN      A       192.168.0.30
moodle  IN      CNAME   hq-rtr
wiki    IN      CNAME   hq-rtr
EOF

# Создание файлов обратных зон
cat <<EOF > /etc/bind/zones/1.168.192.in-addr.arpa
\$TTL    1D
@       IN      SOA     au-team.irpo. root.au-team.irpo. (
                                2024102200      ; serial
                                12H             ; refresh
                                1H              ; retry
                                1W              ; expire
                                1H              ; ncache
                        )
        IN      NS      au-team.irpo.
1       IN      PTR     hq-rtr.au-team.irpo.
62      IN      PTR     hq-srv.au-team.irpo.
14      IN      PTR     hq-cli.au-team.irpo.
EOF

cat <<EOF > /etc/bind/zones/0.168.192.in-addr.arpa
\$TTL    1D
@       IN      SOA     au-team.irpo. root.au-team.irpo. (
                                2024102200      ; serial
                                12H             ; refresh
                                1H              ; retry
                                1W              ; expire
                                1H              ; ncache
                        )
        IN      NS      au-team.irpo.
1       IN      PTR     br-rtr.au-team.irpo.
30      IN      PTR     br-srv.au-team.irpo.
EOF

# Настройка прав доступа к файлам зон
chown bind:bind /etc/bind/zones/*
chmod 640 /etc/bind/zones/*

# Проверка конфигурации зон
named-checkconf -z

# Перезапуск BIND
systemctl restart named

# Проверка работоспособности
echo "Проверка прямой зоны:"
nslookup hq-srv.au-team.irpo 127.0.0.1
echo "Проверка обратной зоны:"
nslookup 192.168.1.62 127.0.0.1


#ФАЙЛОВЫЙ СЕРВЕР требует добавления 3 дисков
mdadm --zero-superblock --force /dev/sd
wipefs --all --force /dev/sd
mdadm --create /dev/md0 -l 5 -n 3 /dev/sd


mkfs -t ext4 /dev/md0
mkdir /etc/mdadm
echo "DEVICE partitions" > /etc/mdadm/mdadm.conf
mdadm --detail --scan | awk '/ARRAY/ {print}' >> /etc/mdadm/mdadm.conf
/dev/md0  /mnt/raid5  ext4  defaults  0  0
mount -a

apt-get install -y nfs-{server,utils}
mkdir /mnt/raid5/nfs
/mnt/raid5/nfs 192.168.1.0/28(rw,no_root_squash)
exportfs -arv
systemctl enable --now nfs-server





