#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
exit 1
fi
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
gitdir=$PWD

##Logging setup
logfile=/var/log/first_run.log
mkfifo ${logfile}.pipe
tee < ${logfile}.pipe $logfile &
exec &> ${logfile}.pipe
rm ${logfile}.pipe

##Functions
function print_status ()
{
    echo -e "\x1B[01;34m[*]\x1B[0m $1"
}

function print_good ()
{
    echo -e "\x1B[01;32m[*]\x1B[0m $1"
}

function print_error ()
{
    echo -e "\x1B[01;31m[*]\x1B[0m $1"
}

function print_notification ()
{
   echo -e "\x1B[01;33m[*]\x1B[0m $1"
}

function error_check
{

if [ $? -eq 0 ]; then
   print_good "$1 successfully."
else
   print_error "$1 failed. Please check $logfile for more details."
exit 1
fi

}

function install_packages()
{

apt-get update &>> $logfile && apt-get install -y --allow-unauthenticated ${@} &>> $logfile
error_check 'Package installation completed'

}

function dir_check()
{

if [ ! -d $1 ]; then
   print_notification "$1 does not exist. Creating.."
   mkdir -p $1
else
   print_notification "$1 already exists. (No problem, We'll use it anyhow)"
fi

}

############################################################################################################################

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

echo -e "${YELLOW}What is the name for the Cuckoo user on this machine?${NC}"
read name

if [ ! -d ~/.cuckoo ]; then
sudo -i -u $name cuckoo 
sleep 20
sudo -i -u $name cp /home/$name/conf/* /home/$name/.cuckoo/conf
sudo -i -u $name cuckoo community
sudo -i -u $name cuckoo migrate
print_status "${YELLOW}Configuring webserver${NC}"
sudo adduser www-data $name  &>> $logfile

sudo -i -u $name cuckoo web --uwsgi > /tmp/cuckoo-web.ini  &>> $logfile
mv /tmp/cuckoo-web.ini /etc/uwsgi/apps-available/
ln -s /etc/uwsgi/apps-available/cuckoo-web.ini /etc/uwsgi/apps-enabled/  &>> $logfile

sudo -i -u $name cuckoo web --nginx > /tmp/cuckoo-web  &>> $logfile
mv /tmp/cuckoo-web /etc/nginx/sites-available/
sed -i -e 's/localhost/0.0.0.0/g' /etc/uwsgi/apps-available/cuckoo-web
ln -s /etc/nginx/sites-available/cuckoo-web /etc/nginx/sites-enabled/ &>> $logfile

sudo -i -u $name cuckoo api --uwsgi > /tmp/cuckoo-api.ini  &>> $logfile
mv /tmp/cuckoo-api.ini /etc/uwsgi/apps-available/
ln -s /etc/uwsgi/apps-available/cuckoo-api.ini /etc/uwsgi/apps-enabled/ &>> $logfile

sudo -i -u $name cuckoo api --nginx > /tmp/cuckoo-api &>> $logfile
mv /tmp/cuckoo-api /etc/nginx/sites-available/
sed -i -e 's/localhost/0.0.0.0/g' /etc/uwsgi/apps-available/cuckoo-api
ln -s /etc/nginx/sites-available/cuckoo-api /etc/nginx/sites-enabled/ &>> $logfile

else
sudo -i -u $name cuckoo community
fi

