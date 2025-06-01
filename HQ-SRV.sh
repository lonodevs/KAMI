#!/bin/bash

hostnamectl set-hostname hq-srv.au-team.irpo
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
EOF
systemctl restart network

#Создание пользователя sshuser и настройка sshd конфига
useradd sshuser -u 1010
echo "sshuser:P@ssw0rd" | chpasswd
usermod -aG wheel sshuser

touch /etc/sudoers
cat <<EOF /etc/sudoers
sshuser ALL=(ALL) NOPASSWD:ALL
EOF


CONFIG_FILE="/etc/openssh/sshd_config"  

# Изменить SSH-порт с 22 на 2024  
awk -i inplace '/^#Port 22$/ { gsub(/22/, "2024"); $0 = "Port 2024" } { print }' "$CONFIG_FILE"  

# Уменьшить MaxAuthTries с 6 до 2  
awk -i inplace '/^#MaxAuthTries 6$/ { gsub(/6/, "2"); $0 = "MaxAuthTries 2" } { print }' "$CONFIG_FILE"  

echo "Allow users = sshuser" >> "$CONFIG_FILE" 


# Разрешить аутентификацию по паролю  
awk -i inplace '/^#PasswordAuthentication yes$/ { sub(/^#/, ""); print; next } { print }' "$CONFIG_FILE"  


touch /etc/openssh/bannermotd  
cat <<EOF > /etc/openssh/bannermotd 

----------------------  
Authorized access only  
----------------------  
EOF  

systemctl restart sshd  
echo "AllowUsers sshuser" | tee -a /etc/openssh/sshd_config


apt-get update && apt-get install -y dnsmasq
cat > /etc/dnsmasq.conf <<EOF
no-resolv
no-poll
no-hosts
listen-address=192.168.1.62

server=77.88.8.8
server=8.8.8.8

cache-size=1000
all-servers
no-negcache

host-record=hq-rtr.au-team.irpo,192.168.1.1
host-record=hq-srv.au-team.irpo,192.168.1.62
host-record=hq-cli.au-team.irpo,192.168.1.66

address=/br-rtr.au-team.irpo/192.168.0.1
address=/br-srv.au-team.irpo/192.168.0.30

cname=moodle.au-team.irpo,hq-rtr.au-team.irpo
cname=wiki.au-team.irpo,hq-rtr.au-team.irpo
EOF
systemctl restart dnsmasq
apt-get install -y chrony
cat <<EOF > /etc/chrony.conf
# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (https://www.pool.ntp.org/join.html).
#pool pool.ntp.org iburst
server 192.168.1.62 iburst prefer
# Record the rate at which the system clock gains/losses time.
driftfile /var/lib/chrony/drift

# Allow the system clock to be stepped in the first three updates
# if its offset is larger than 1 second.
makestep 1.0 3

# Enable kernel synchronization of the real-time clock (RTC).
rtcsync

# Enable hardware timestamping on all interfaces that support it.
#hwtimestamp *

# Increase the minimum number of selectable sources required to adjust
# the system clock.
#minsources 2

# Allow NTP client access from local network.
#allow 192.168.0.0/16

# Serve time even if not synchronized to a time source.
#local stratum 10

# Require authentication (nts or key option) for all NTP sources.
#authselectmode require

# Specify file containing keys for NTP authentication.
#keyfile /etc/chrony.keys

# Save NTS keys and cookies.
ntsdumpdir /var/lib/chrony

# Insert/delete leap seconds by slewing instead of stepping.
#leapsecmode slew

# Get TAI-UTC offset and leap seconds from the system tz database.
#leapsectz right/UTC

# Specify directory for log files.
logdir /var/log/chrony

# Select which information is logged.
#log measurements statistics tracking
EOF


#Установка Moodle
#apt-get install -y moodle moodle-apache2 moodle-base moodle-local-mysql phpMyAdmin
#systemctl enable --now mysqld
#mysqladmin password 'P@ssw0rd'
#cat /etc/httpd2/conf/include/Directory_moodle_default.conf | grep 'Require all granted' || sed -i '/AllowOverride None/a Require all granted' /etc/httpd2/conf/include/Directory_moodle_default.conf
#sed -i 's/; max_input_vars = 1000/max_input_vars = 5000/g' /etc/php/8.2/apache2-mod_php/php.ini
#systemctl enable --now httpd2
#mysql -u root -p
#create user 'moodle'@'localhost' identified by 'P@ssw0rd';
#create database moodledb default character set utf8 collate utf8_unicode_ci;
#grant all privileges on moodledb.* to moodle@localhost;

