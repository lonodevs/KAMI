
ena
conf t
hostname br-srv
ip domain-name au-team.irpo


ntp timezone utc+4


interface int0
  description "to isp"
  ip address 172.16.5.14/28


port te0
  service-instance te0/int0
    encapsulation untagged


interface int0
  connect port te0 service-instance te0/int0


interface int1
  description "to hq-srv"
  ip address 192.168.0.1/27


port te1
  service-instance te1/int1
    encapsulation untagged


interface int1
  connect port te1 service-instance te1/int1


ip route 0.0.0.0 0.0.0.0 172.16.5.1


username net_admin
password P@ssw0rd
role admin


int tunnel.0
ip add 172.16.0.2/30
ip mtu 1400
ip tunnel 172.16.5.14 172.16.4.14 mode gre


router ospf 1
  router-id 2.2.2.2
  network 172.16.0.0/30 area 0
  network 192.168.0.0/27 area 0 
  passive-interface default
  no passive-interface tunnel.0

int tunnel.0
ip ospf authetication message-digest
ip ospf message-digest-key 1 md5 P@ssw0rd

int int1
  ip nat inside
int int0
  ip nat outside
ip nat pool NAT_POOL 192.168.0.1-192.168.0.30
ip nat source dynamic inside-to-outside pool NAT_POOL overload interface int0

ip nat source static tcp 192.168.0.1 80 192.168.0.30 8080
ip nat source static tcp 192.168.0.1 2024 192.168.0.30 2024
