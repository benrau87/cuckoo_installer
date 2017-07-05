#!/bin/bash
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

echo 1 | tee -a /proc/sys/net/ipv4/ip_forward 
sysctl -w net.ipv4.ip_forward=1 

sleep 5

cuckoo rooter &

ON=$(ifconfig -a | grep -cs 'vboxnet0')

if [[ $ON == 1 ]]
then
  echo "Host only interface is up"
  VBoxManage hostonlyif ipconfig vboxnet0 --ip 10.1.1.254
else
  VBoxManage hostonlyif create vboxnet0
  VBoxManage hostonlyif ipconfig vboxnet0 --ip 10.1.1.254
fi

su - steve -c 'cuckoo xterm -hold -e' &
su - steve -c 'cuckoo xterm -hold -e cuckoo -d process auto' &
su - steve -c 'cuckoo xterm -hold -e cuckoo web runserver 0.0.0.0:8000' &


