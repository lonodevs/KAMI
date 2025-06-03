
hostnamectl set-hostname hq-srv.au-team.irpo
apt-get install -y tzdata
timedatectl set-timezone Europe/Samara

#Создание пользователя sshuser и настройка sshd конфига
useradd sshuser -u 1015
echo "sshuser:P@ssw0rd" | chpasswd
usermod -aG wheel sshuser

touch /etc/sudoers
vim /etc/sudoers
sshuser ALL=(ALL) NOPASSWD:ALL

apt-get update && apt-get install -y dnsmasq
cat > /etc/dnsmasq.conf <<EOF
no-resolv
no-poll
no-hosts
listen-address=192.168.18.30

server=77.88.8.8
server=8.8.8.8

cache-size=1000
all-servers
no-negcache

host-record=hq-rtr.au-team.irpo,192.168.18.1
host-record=hq-srv.au-team.irpo,192.168.18.30
host-record=hq-cli.au-team.irpo,192.168.18.34

address=/br-rtr.au-team.irpo/192.168.24.1
address=/br-srv.au-team.irpo/192.168.24.14

cname=moodle.au-team.irpo,isp.au-team.irpo
cname=wiki.au-team.irpo,isp.au-team.irpo
EOF
systemctl restart dnsmasq

NFS
СУС 2.2
mdadm --create --verbose /dev/md0 -l 0 -n 3 /dev/sd{b,c,d}




