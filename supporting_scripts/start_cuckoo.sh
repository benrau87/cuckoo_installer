#!/bin/bash
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ON=$(ifconfig -a | grep -cs 'vboxnet0')

if [[ $ON == 1 ]]
then
  echo "Host only interface is up"
  VBoxManage hostonlyif ipconfig vboxnet0 --ip 10.1.1.254
else
  VBoxManage hostonlyif create vboxnet0
  VBoxManage hostonlyif ipconfig vboxnet0 --ip 10.1.1.254
fi

xterm -hold -e cuckoo &
xterm -hold -e cuckoo process auto &
xterm -hold -e cuckoo web 0.0.0.0:8000 &

