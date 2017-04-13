#!/bin/bash
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ON=$(ifconfig -a | grep -cs 'vboxnet0')

if [[ $ON == 1 ]]
then
  echo "Host only interface is up"
else 
VBoxManage hostonlyif create
VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1
fi

cd /etc/cuckoo/utils/
rm -f /tmp/gitpull_output.txt
git checkout > /tmp/gitpull_output.txt

if grep -q "behind" /tmp/gitpull_output.txt
then
echo -e "${YELLOW}Your branch is behind, you may think of updating with git pull.${NC}"
else
echo "Your branch is up to date"
fi

python /etc/cuckoo/utils/community.py --force --all
cd /etc/cuckoo/web/
./manage.py migrate
./manage.py runserver 0.0.0.0:8000 &
cd ..
./cuckoo.py --debug
