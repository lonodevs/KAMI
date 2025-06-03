
#Переименование виртуалки
hostnamectl set-hostname br-srv.au-team.irpo;
apt-get install -y tzdata
timedatectl set-timezone Europe/Samara
useradd sshuser -u 1015
echo "sshuser:P@ssw0rd" | chpasswd
usermod -aG wheel sshuser

touch /etc/sudoers
vim /etc/sudoers
sshuser ALL=(ALL) NOPASSWD:ALL

#Создание Samba DC
apt-get update && apt-get install -y task-samba-dc bind 
control bind-chroot disabled
grep -q KRB5RCACHETYPE /etc/sysconfig/bind || echo 'KRB5RCACHETYPE="none"' >> /etc/sysconfig/bind
systemctl stop bind
rm -f /etc/samba/smb.conf
rm -rf /var/lib/samba
rm -rf /var/cache/samba
mkdir -p /var/lib/samba/sysvol
samba-tool domain provision 
systemctl restart samba
systemctl enable --now samba
samba-tool domain info 127.0.0.1
samba-tool computer list
samba-tool group add hq
for i in {1..5}; do
samba-tool user add user$i-hq P@ssw0rd;
samba-tool user setexpiry user$i-hq --noexpiry;
samba-tool group addmembers "hq" user$i-hq;
done
apt-get install -y admx-*
amdx-msi-setup

#Настройка Ansible
apt-get install -y ansible sshpass
sed -i 's/^#inventory      = \/etc\/ansible\/hosts/inventory      = \/etc\/ansible\/hosts/' /etc/ansible/ansible.cfg 
echo "host_key_checking  False" | tee -a /etc/ansible/ansible.cfg
cat > /etc/ansible/hosts <<EOF
HQ-RTR ansible_host=192.168.18.1 ansible_user=net_admin ansible_password=P@$$word ansible_connection=network_cli ansible_network_os=ios
BR-RTR ansible_host=192.168.24.1 ansible_user=net_admin ansible_password=P@$$word ansible_connection=network_cli ansible_network_os=ios
HQ-SRV ansible_host=192.168.18.30 ansible_user=sshuser ansible_password=P@ssw0rd ansible_ssh_port=3015
HQ-CLI ansilbe_host=192.168.18.34 ansible_user=sshuser ansible_password=P@ssw0rd ansible_ssh_port=3015

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
ansible -m ping all
