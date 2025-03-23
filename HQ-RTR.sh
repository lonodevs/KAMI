#ВКЛЮЧЕНИЕ
ena
conf t
hostname HQ-RTR

ntp timezone utc+4

#СОЗДАНИЕ ЛОГИЧЕСОГО ИНТЕРФЕЙСА
interface int0
  description "to isp"
  ip address 172.16.4.2/28

#СОЗДАНИЕ К ФИЗ. ИНТЕРФЕЙСА
port te0
  service-instance te0/int0
    encapsulation untagged

#ПРИВЯЗКА К ФИЗИЧЕСКОМУ ИНТЕФЕЙСУ
interface int0
  connect port te0 service-instance te0/int0

#НАСТРОЙКА ИНТЕРФЕСОВ ДЛЯ ВЛАНОВ
interface int1
  description "to hq-srv"
  ip address 192.168.1.1/26
interface int2
  description "to hq-cli"
  ip address 192.168.1.65/28

#ГОТОВИМ ФИЗИЧЕСКИЕ ИНТЕРФЕЙСЫ
port te1
  service-instance te1/int1
    encapsulation dot1q 100
    rewrite pop 1
  service-instance te1/int2
    encapsulation dot1q 200
    rewrite pop 1

#ПРИВЯЗЫВАЕМ К ФИЗ ИНТЕРФЕЙСАМ
interface int1
  connect port te1 service-instance te1/int1
interface int2
  connect port te1 service-instance te1/int2

#МАРШРУТ ПО УМОЛЧАНИЮ
ip route 0.0.0.0 0.0.0.0 172.16.4.1

#СОЗДАНИЕ ПОЛЬЗОВАТЕЛЯ
username net_admin
password P@ssw0rd
role admin

#НАСТРОЙКА ТУННЕЛЯ
int tunnel.0
ip add 172.16.0.1/30
ip mtu 1400
ip tunnel 172.16.4.2 172.16.5.2 mode gre

#НАСТРОЙКА ОСПФ
router ospf 1
  router-id 1.1.1.1
  network 172.16.0.0/30 area 0
  network 192.168.1.0/26 area 0
  network 192.168.1.0/28 area 0
  passive-interface default
  no passive-interface tunnel.0

#НАСТРОЙКА NAT
int int1
  ip nat inside
int int2
  ip nat inside
int int0
  ip nat outside

ip nat pool NAT_POOL 192.168.1.1-192.168.1.62,192.168.1.65-192.168.1.78
ip nat source dynamic inside-to-outside pool NAT_POOL overload interface int0

#НАСТРОЙКА DHCP
ip pool hq-cli 192.168.1.66-192.168.1.78
dhcp-server 1
  pool hq-cli 1
    mask 28
    gateway 192.168.1.65
    dns 192.168.100.62
    domain-name au-team.irpo
    
interface int2
dhcp-server 1
