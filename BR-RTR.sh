#ВКЛЮЧЕНИЕ
ena
conf t
hostname BR-RTR

ntp timezone utc+4

#СОЗДАНИЕ ЛОГИЧЕСОГО ИНТЕРФЕЙСА
interface int0
  description "to isp"
  ip address 172.16.5.2/28

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
  ip address 192.168.0.1/27

#НАСТРОЙКА ФИЗ.ИНТЕРФЕЙСА
port te1
  service-instance te1/int1
    encapsulation untagged

#ОБЪЕДИНЕНИЕ ФИЗ И ЛОГ ПОРТА
interface int1
  connect port te1 service-instance te1/int1

#ПРОПИСЫВАЕМ МАРШРУТ ПО СТАНДАРТУ
ip route 0.0.0.0 0.0.0.0 172.16.5.1

#СОЗДАНИЕ ПОЛЬЗОВАТЕЛЯ
username net_admin
password P@ssw0rd
role admin

#НАСТРОЙКА ТУННЕЛЯ
int tunnel.0
ip add 172.16.0.2/30
ip mtu 1400
ip tunnel 172.16.5.2 172.16.4.2 mode gre

#НАСТРОЙКА ОСПФ
router ospf 1
  router-id 2.2.2.2
  network 172.16.0.0/30 area 0
  network 192.168.0.0/27 area 0 
  passive-interface default
  no passive-interface tunnel.0

#НАСТРОЙКА NAT
int int1
  ip nat inside
int int0
  ip nat outside
ip nat pool NAT_POOL 192.168.0.1-192.168.0.30
ip nat source dynamic inside-to-outside pool NAT_POOL overload interface int0

#СТАТИЧЕСКИЙ ПРОБРОС
ip nat source static tcp 192.168.0.1 80 192.168.0.30 8080
ip nat source static tcp 192.168.0.1 2024 192.168.0.30 2024
