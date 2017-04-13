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
logfile=/var/log/tor_install.log
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
############################################################################################################################
############################################################################################################################
############################################################################################################################

print_status "${YELLOW}Installing Tor..${NC}"
apt-get update -y &>> $logfile
echo "deb http://deb.torproject.org/torproject.org xenial main" |  sudo tee -a /etc/apt/sources.list &>> $logfile
echo "deb-src http://deb.torproject.org/torproject.org xenial main" |  sudo tee -a /etc/apt/sources.list &>> $logfile
gpg --keyserver keys.gnupg.net --recv A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 &>> $logfile
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add - &>> $logfile
apt-get update &>> $logfile
apt-get install tor deb.torproject.org-keyring -y &>> $logfile
error_check 'Tor installed'

print_status "${YELLOW}Downloading Tor Route..${NC}"
git clone https://github.com/seanthegeek/routetor.git &>> $logfile
error_check 'TorRoute downloaded'
print_status "${YELLOW}Configuring Tor...${NC}"
echo "TransListenAddress 192.168.56.1" | sudo tee -a /etc/tor/torrc &>> $logfile
echo "TransPort 9040" | sudo tee -a /etc/tor/torrc &>> $logfile
echo "DNSListenAddress 192.168.56.1" | sudo tee -a /etc/tor/torrc &>> $logfile
echo "DNSPort 5353" | sudo tee -a /etc/tor/torrc &>> $logfile
error_check 'TorRoute downloaded'
service tor restart
cd routetor
sudo cp *tor* /usr/sbin &>> $logfile
error_check 'TorRoute scripts installed'


print_status "${YELLOW}Adding cron job for starting Tor at boot..${NC}"
crontab -l | { cat; echo "@reboot /usr/sbin/routetor"; } | crontab -
error_check 'Cron job added'

print_status "${YELLOW}Starting Routetor${NC}"
/usr/sbin/routetor &
