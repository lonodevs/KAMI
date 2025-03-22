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


apt-get install -y bind bind-utils


listen-on { 127.0.0.1; 192.168.100.62; };

forwarders { 77.88.8.8; };

allow-query { 192.168.100.0/26; 192.168.200.0/28; 192.168.0.0/27; };
