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
logfile=/var/log/cuckoo_install.log
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
########################################
##BEGIN MAIN SCRIPT##

###Add Repos
print_status "${YELLOW}Adding Repositories${NC}"
##Mongodb
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6 &>> $logfile
echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list &>> $logfile
error_check 'Mongodb repo added'

##Java
print_status "${YELLOW}Removing any old Java sources, apt-get packages.${NC}"
rm /var/lib/dpkg/info/oracle-java7-installer*  &>> $logfile
rm /var/lib/dpkg/info/oracle-java8-installer*  &>> $logfile
apt-get purge oracle-java7-installer -y &>> $logfile
apt-get purge oracle-java8-installer -y &>> $logfile
rm /etc/apt/sources.list.d/*java*  &>> $logfile
dpkg -P oracle-java7-installer  &>> $logfile
dpkg -P oracle-java8-installer  &>> $logfile
apt-get -f install  &>> $logfile
add-apt-repository ppa:webupd8team/java -y &>> $logfile
error_check 'Java repo added'

##Elasticsearch
#wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add - &>> $logfile
#echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | tee /etc/apt/sources.list.d/elasticsearch-2.x.list &>> $logfile
error_check 'Elasticsearch repo added'
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add - &>> $logfile
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list &>> $logfile

##Suricata
add-apt-repository ppa:oisf/suricata-beta -y &>> $logfile
error_check 'Suricata repo added'

####End of repos
##Holding pattern for dpkg...
print_status "${YELLOW}Waiting for dpkg process to free up...${NC}"
print_status "${YELLOW}If this takes too long try running ${RED}sudo rm -f /var/lib/dpkg/lock${YELLOW} in another terminal window.${NC}"
while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
   sleep 1
done

### System updates
print_status "${YELLOW}You will need to enter some stuff in for Moloch after the system update, dont go too far...${NC}"
print_status "${YELLOW}Performing apt-get update and upgrade (May take a while if this is a fresh install)..${NC}"
apt-get update &>> $logfile && apt-get -y dist-upgrade &>> $logfile
error_check 'Updated system'

##APT Packages
print_status "${YELLOW}Downloading and installing depos${NC}"
apt-get install -y build-essential checkinstall &>> $logfile
chmod u+rwx /usr/local/src &>> $logfile
apt-get install -y linux-headers-$(uname -r) &>> $logfile
install_packages python python-dev python-pip python-setuptools python-sqlalchemy python-virtualenv make automake libdumbnet-dev libarchive-dev libcap2-bin libconfig-dev libcrypt-ssleay-perl libelf-dev libffi-dev libfuzzy-dev libgeoip-dev libjansson-dev libjpeg-dev liblwp-useragent-determined-perl liblzma-dev libmagic-dev libpcap-dev libpcre++-dev libpq-dev libssl-dev libtool apparmor-utils apt-listchanges bison byacc clamav clamav-daemon clamav-freshclam dh-autoreconf elasticsearch fail2ban flex gcc mongodb-org suricata swig tcpdump tesseract-ocr unattended-upgrades uthash-dev virtualbox zlib1g-dev wkhtmltopdf xvfb xfonts-100dpi libstdc++6:i386 libgcc1:i386 zlib1g:i386 libncurses5:i386 apt-transport-https software-properties-common python-software-properties libwww-perl libjson-perl ethtool ansible parallel 
##Python Modules
print_status "${YELLOW}Downloading and installing Cuckoo and Python dependencies${NC}"
pip install -U pip setuptools &>> $logfile
pip install -U pip flex &>> $logfile
pip install -U pip distorm3 &>> $logfile
pip install -U pip pycrypto &>> $logfile
pip install -U pip weasyprint &>> $logfile
pip install -U pip yara-python &>> $logfile
pip install -I ansible==2.1.1.0 &>> $logfile

##Java 
print_status "${YELLOW}Installing Java${NC}"
echo debconf shared/accepted-oracle-license-v1-1 select true | \
  sudo debconf-set-selections &>> $logfile
apt-get install oracle-java8-installer -y &>> $logfile
error_check 'Java Installed'

error_check 'Depos installed'
