#!/bin/bash
####################################################################################################################
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
gitdir=$PWD

##Logging setup
logfile=/var/log/moloch_install.log
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

apt-get update &>> $logfile && apt-get -y dist-upgrade &>> $logfile && apt-get install -y --allow-unauthenticated ${@} &>> $logfile
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
#Pre checks: These are a couple of basic sanity checks the script does before proceeding.

echo -e "${YELLOW}We need to create a local Moloch admin and need a password, please type one.${NC}"
read THEPASSWORD


echo -e "${YELLOW}Removing any old Java sources, apt-get packages.${NC}"
rm /var/lib/dpkg/info/oracle-java7-installer*  &>> $logfile
rm /var/lib/dpkg/info/oracle-java8-installer*  &>> $logfile
apt-get purge oracle-java7-installer -y &>> $logfile
apt-get purge oracle-java8-installer -y &>> $logfile
rm /etc/apt/sources.list.d/*java*  &>> $logfile
dpkg -P oracle-java7-installer  &>> $logfile
dpkg -P oracle-java8-installer  &>> $logfile
apt-get -f install  &>> $logfile

print_status "${YELLOW}Installing dependencies and updates${NC}"
apt-get update &>> $logfile
install_packages apt-transport-https python build-essential software-properties-common python-software-properties &>> $logfile
##Java
add-apt-repository ppa:webupd8team/java -y &>> $logfile
##Elasticsearch
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add - &>> $logfile
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list &>> $logfile
apt-get update &>> $logfile
install_packages libwww-perl libjson-perl ethtool
error_check 'Dependencies updated'
cd ~

ES=5.4
NODEJS=6.10.3
INSTALL_DIR=$PWD


##Pfring
echo -n "Use pfring? ('yes' enables) [no] "
read USEPFRING
PFRING=""
if [ -n "$USEPFRING" -a "x$USEPFRING" = "xyes" ]; then
echo "MOLOCH - Using pfring - Make sure to install the kernel modules"
sleep 1
PFRING="--pfring"
fi

##Java install for elasticsearch
print_status "${YELLOW}Installing Java${NC}"
echo debconf shared/accepted-oracle-license-v1-1 select true | \
  sudo debconf-set-selections &>> $logfile
apt-get install oracle-java8-installer -y &>> $logfile
error_check 'Java Installed'

## ElasticSearch
print_status "${YELLOW}Downloading and installing Elasticsearch${NC}"
if [ ! -f "elasticsearch-${ES}.tar.gz" ]; then
apt-get install -y elasticsearch &>> $logfile
error_check 'Elasticsearch Installed'
print_status "${YELLOW}Setting up Elasticsearch${NC}"
systemctl daemon-reload &>> $logfile
systemctl enable elasticsearch.service &>> $logfile
systemctl start elasticsearch.service &>> $logfile
error_check 'Elasticsearch service setup'
fi

# NodeJS
#print_status "${YELLOW}Downloading and installing NodeJS${NC}"
#if [ ! -f "node-v${NODEJS}.tar.gz" ]; then
#wget http://nodejs.org/dist/v${NODEJS}/node-v${NODEJS}.tar.gz  &>> $logfile
#fi

#tar xfz node-v${NODEJS}.tar.gz   &>> $logfile
#cd node-v${NODEJS}  &>> $logfile
#./configure  &>> $logfile
#make  &>> $logfile
#make install  &>> $logfile
#./configure --prefix=${TDIR}  &>> $logfile
#make install  &>> $logfile
#error_check 'NodeJS installed'


##Moloch
print_status "${YELLOW}Downloading and installing Moloch${NC}"
wget https://files.molo.ch/builds/ubuntu-16.04/moloch_0.18.2-1_amd64.deb &>> $logfile
dpkg -i moloch* &>> $logfile
bash /data/moloch/bin/Configure 
bash/ data/moloch/bin/moloch_add_user.sh admin "Admin User" $THEPASSWORD --admin &>> $logfile
perl /data/moloch/db/db.pl http://localhost:9200 init &>> $logfile
systemctl start molochcapture.service &>> $logfile
service molochcapture start &>> $logfile
systemctl start molochviewer.service &>> $logfile
service molochviewer start &>> $logfile
error_check 'Moloch Installed'

echo -e "${YELLOW}Moloch installed successfully, navigate to $HOSTNAME:8005 to view.${NC}"
#git clone https://github.com/aol/moloch.git

#git clone https://github.com/benrau87/MolochSetup.git

#cp MolochSetup/Moloch\ Script.sh ~/moloch/

#cd moloch

#bash Moloch\ Script.sh

