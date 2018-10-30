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
export DEBIAN_FRONTEND=noninteractive
########################################
##BEGIN MAIN SCRIPT##
#Pre checks: These are a couple of basic sanity checks the script does before proceeding.
print_status "${YELLOW}Running VT-x check${NC}"
if [ "$(lscpu | grep VT-x | wc -l)" != "1" ]; then
echo -e "${RED}NOTICE: You cannot install 64-bit VMs or IRMA on this machine due to VT-x instruction set missing.${NC}"
else
vtx=true
echo -e "${YELLOW}NOTICE: VT-x instruction set found.${NC}"
fi
echo -e "${YELLOW}We need to create a local account to run your Cuckoo sandbox from; What would you like your Cuckoo account username to be?${NC}"
read name
adduser $name --gecos ""
echo -e "${YELLOW}Please type in a MySQL root password${NC}"
read root_mysql_pass
echo -e "${YELLOW}Please type in a MySQL cuckoo password${NC}"
read cuckoo_mysql_pass
echo -e "${RED}Active interfaces${NC}"
for iface in $(ifconfig | cut -d ' ' -f1| tr '\n' ' ')
do 
  addr=$(ip -o -4 addr list $iface | awk '{print $4}' | cut -d/ -f1)
  printf "$iface\t$addr\n"
done
echo -e "${YELLOW}What is the name of the interface you wish to route traffic through?(ex: eth0)${NC}"
read interface

##Create directories and scripts for later
print_status "${YELLOW}Configuring local files and scripts${NC}"
cd /home/$name/
dir=$PWD
dir_check /home/$name/tools
dir_check /home/$name/conf
sed -i "s/internet = ens33/internet = $interface/g" $gitdir/conf/routing.conf &>> $logfile
sed -i "s/qwe123/$interface/g" $gitdir/supporting_scripts/vmcloak.sh &>> $logfile
sed -i "s/steve/$name/g" $gitdir/supporting_scripts/vmcloak.sh &>> $logfile
sed -i "s/steve/$name/g" $gitdir/supporting_scripts/restart_cuckoo.sh &>> $logfile
sed -i "s/steve/$name/g" $gitdir/supporting_scripts/update_signatures.sh &>> $logfile
sed -i "s/ens160/$interface/g" $gitdir/lib/snort.service &>> $logfile
cp $gitdir/conf/* /home/$name/conf
cp $gitdir/supporting_scripts/vmcloak.sh /home/$name/
cp $gitdir/supporting_scripts/start_routing.sh /home/$name/
cp $gitdir/supporting_scripts/import_vbox_ova.sh /home/$name/
chmod +x /home/$name/start_routing.sh
chmod +x /home/$name/vmcloak.sh
chmod +x /home/$name/import_vbox_ova.sh
chown $name:$name /home/$name/import_vbox_ova.sh
chmod +x  $gitdir/supporting_scripts/update_signatures.sh
cp $gitdir/supporting_scripts/update_signatures.sh /home/$name/
chown $name:$name -R /home/$name/conf
chown $name:$name -R /home/$name/vmcloak.sh
chmod +x $gitdir/supporting_scripts/restart_cuckoo.sh
cp $gitdir/supporting_scripts/restart_cuckoo.sh /home/$name/
cd tools/

##Checks
if [ "$(cat /etc/apt/sources.list | grep multiverse | wc -l)" -ge "1" ]; then
 multi_check=true
fi

###Add Repos
##Ubuntu 18 sources and checks
if [ "$multi_check" == "true" ]; then
print_status "${YELLOW}Ubuntu Default Repos Exist..Skipping${NC}"
else
print_status "${YELLOW}Adding Repositories${NC}"
add-apt-repository universe &>> $logfile
fi
apt-get update &>> $logfile
apt-get install locate -y  &>> $logfile
updatedb  &>> $logfile

##Check for existing depos
if [ "$(ls /etc/apt/sources.list.d | grep mongodb-org-3.6.list | wc -l)" -ge "1" ]; then
 mongo_check=true
fi
if [ "$(ls /etc/apt/sources.list.d/ | grep virtualbox.list| wc -l)" -ge "1" ]; then
 virtualbox_check=true
fi
if [ "$(ls /etc/apt/sources.list.d/ | grep elastic-5| wc -l)" -ge "1" ]; then
 elastic_check=true
fi
if [ "$(which suricata | wc -l)" -ge "1" ]; then
 suricata_check=true
fi
if [ "$(which snort | wc -l)" -ge "1" ]; then
 snort_check=true
fi
if [ "$(which snort | wc -l)" -ge "1" ]; then
 snort_check=true
fi
if [ "$(locate /etc/systemd/system/elasticsearch.service | wc -l)" -ge "1" ]; then
 elasticservice_check=true
fi
if [ "$(which yara | wc -l)" -ge "1" ]; then
 yara_check=true
fi
if [ "$(which dtrace | wc -l)" -ge "1" ]; then
 dtrace_check=true
fi
if [ "$(locate dist-package/pydeep | wc -l)" -ge "1" ]; then
 pydeep_check=true
fi
if [ "$(which mysql | wc -l)" -ge "1" ]; then
 mysql_check=true
fi
if [ "$(cat /home/$name/conf/cuckoo.conf | grep localhost/cuckoo | wc -l)" -ge "1" ]; then
 mysqlconf_check=true
fi
if [ "$(locate /usr/local/bin/vol.py | wc -l)" -ge "1" ]; then
 vol_check=true
fi
if [ "$(cat /etc/apt/sources.list | grep torproject | wc -l)" -ge "1" ]; then
 tor_check=true
fi

###Depo Additions
##Mongodb
if [ "$mongo_check" == "true" ]; then
print_status "${YELLOW}Skipping Mongo Repos${NC}"
else
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5 &>> $logfile
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.6 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.6.list &>> $logfile
error_check 'Mongodb repo added'
fi

##Tor
if [ "$tor_check" == "true" ]; then
print_status "${YELLOW}Skipping Tor Repos${NC}"
else
echo "deb https://deb.torproject.org/torproject.org bionic main" |  sudo tee -a /etc/apt/sources.list &>> $logfile
echo "deb-src https://deb.torproject.org/torproject.org bionic main" |  sudo tee -a /etc/apt/sources.list &>> $logfile
gpg --keyserver keys.gnupg.net --recv A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 &>> $logfile
gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | sudo apt-key add - &>> $logfile
error_check 'Tor repo added'
fi

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
if [ "$elastic_check" == "true" ]; then
print_status "${YELLOW}Skipping Elastic Repos${NC}"
else
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add - &>> $logfile
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-5.x.list &>> $logfile
error_check 'Elasticsearch repo added'
fi

##Suricata
if [ "$suricata_check" == "true" ]; then
print_status "${YELLOW}Skipping Suricata Repos${NC}"
else
add-apt-repository ppa:oisf/suricata-beta -y &>> $logfile
error_check 'Suricata repo added'
fi

##Virtualbox
if [ "$virtualbox_check" == "true" ]; then
print_status "${YELLOW}Skipping Virtualbox Repos${NC}"
else
wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -
sudo sh -c 'echo "deb http://download.virtualbox.org/virtualbox/debian $(lsb_release -sc) contrib" >> /etc/apt/sources.list.d/virtualbox.list'
error_check 'Virtualbox repo added'
fi

####End of repos
##Holding pattern for dpkg...
print_status "${YELLOW}Waiting for dpkg process to free up...${NC}"
print_status "${YELLOW}If this takes too long try running ${RED}sudo rm -f /var/lib/dpkg/lock${YELLOW} in another terminal window. You can also check the stdout for any issues by running tail -f /var/log/cuckoo_install.log${NC}"
while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
   sleep 1
done

### System updates
#print_status "${YELLOW}You will need to enter some stuff in for Moloch after the system update, dont go too far...${NC}"
print_status "${YELLOW}Performing apt-get update and upgrade (May take a while if this is a fresh install)..${NC}"
apt-get update &>> $logfile && apt-get -y dist-upgrade &>> $logfile
error_check 'Updated system'

##APT Packages
print_status "${YELLOW}Downloading and installing depos needed for installtion script${NC}"
apt-get install -y build-essential checkinstall &>> $logfile
error_check 'Build Essentials Installed'

##Java 
print_status "${YELLOW}Installing Java${NC}"
apt-get install -y --no-install-recommends openjdk-8-jre-headless -y &>> $logfile
error_check 'Java Installed'

chmod u+rwx /usr/local/src &>> $logfile
apt-get install -y linux-headers-$(uname -r) &>> $logfile
#libstdc++6:i386 libgcc1:i386 zlib1g:i386 libncurses5:i386
print_status "${YELLOW}Installing Apt Depos${NC}"
install_packages python python-dev python-pip python-setuptools python-sqlalchemy python-virtualenv make automake libboost-all-dev libdumbnet-dev libarchive-dev libcap2-bin libconfig-dev libcrypt-ssleay-perl libelf-dev libffi-dev libfuzzy-dev libgeoip-dev libjansson-dev libjpeg-dev liblwp-useragent-determined-perl liblzma-dev libmagic-dev libpcap-dev libpcre++-dev libpq-dev libssl-dev libtool apparmor-utils apt-listchanges bison byacc clamav clamav-daemon clamav-freshclam dh-autoreconf elasticsearch fail2ban flex gcc mongodb-org suricata swig tcpdump tesseract-ocr unattended-upgrades uthash-dev zlib1g-dev wkhtmltopdf xvfb xfonts-100dpi apt-transport-https software-properties-common libwww-perl libjson-perl ethtool parallel vagrant exfat-utils exfat-fuse xterm uwsgi uwsgi-plugin-python nginx libguac-client-rdp0 libguac-client-vnc0 libguac-client-ssh0 guacd virtualbox-5.2
error_check 'Apt Depos installed'

print_status "${YELLOW}Downloading and installing Virtualbox Extension${NC}"
vboxversion=$(wget -qO - http://download.virtualbox.org/virtualbox/LATEST.TXT) &>> $logfile
wget "http://download.virtualbox.org/virtualbox/${vboxversion}/Oracle_VM_VirtualBox_Extension_Pack-${vboxversion}.vbox-extpack" &>> $logfile
echo "y" | vboxmanage extpack install --replace Oracle_VM_VirtualBox_Extension_Pack-${vboxversion}.vbox-extpack &>> $logfile
error_check 'Virtualbox Extensions installed'

##Python Modules
print_status "${YELLOW}Downloading and installing Cuckoo and Python dependencies${NC}"
pip install --upgrade pip==9.0.3 &>> $logfile
pip install setuptools &>> $logfile
pip install flex &>> $logfile
pip install distorm3 &>> $logfile
pip install pycrypto &>> $logfile
pip install weasyprint &>> $logfile
pip install yara-python &>> $logfile
pip install m2crypto==0.24.0  &>> $logfile
#pip install -U pip cuckoo==2.0.4a5 &>> $logfile
pip install cuckoo &>> $logfile
error_check 'Cuckoo and depos downloaded and installed'

##Cuckoo Add-ons
##Elasticsearch
if [ "$elasticservice_check" == "true" ]; then
print_status "${YELLOW}Elastic Service enabled, skipping config${NC}"
else
print_status "${YELLOW}Setting up Elasticsearch${NC}"
systemctl daemon-reload &>> $logfile
systemctl enable elasticsearch.service &>> $logfile
systemctl start elasticsearch.service &>> $logfile
error_check 'Elasticsearch Setup'
fi

##Precheck because Java sucks ass
service elasticsearch start
sleep 5
if [ "$(ps aux | grep elastic | wc -l)" -gt "1" ]; then
print_status "${YELLOW}Java and elastic running${NC}"
else
	print_error "Please rerun this script or manually enable elasticsearch"
exit 1
fi

##Yara
if [ "$yara_check" == "true" ]; then
print_status "${YELLOW}Yara installed, skipping config${NC}"
else
print_status "${YELLOW}Downloading Yara${NC}"
cd $gitdir
git clone https://github.com/VirusTotal/yara.git &>> $logfile
error_check 'Yara downloaded'
print_status "${YELLOW}Building and compiling Yara${NC}"
cd yara/
./bootstrap.sh &>> $logfile
./configure --with-crypto --enable-cuckoo --enable-magic &>> $logfile
error_check 'Yara compiled and built'
print_status "${YELLOW}Installing Yara${NC}"
make &>> $logfile
make install &>> $logfile
make check &>> $logfile
error_check 'Yara installed'
fi

##Pydeep
if [ "$pydeep_check" == "true" ]; then
print_status "${YELLOW}Pydeep installed, skipping config${NC}"
else
cd $gitdir
print_status "${YELLOW}Setting up Pydeep${NC}"
sudo -H pip install git+https://github.com/kbandla/pydeep.git &>> $logfile
error_check 'Pydeep installed'
fi

##Volatility
if [ "$vol_check" == "true" ]; then
print_status "${YELLOW}Volatility installed, skipping config${NC}"
else
cd $gitdir
print_status "${YELLOW}Setting up Volatility${NC}"
wget https://github.com/volatilityfoundation/volatility/archive/2.5.zip &>> $logfile
error_check 'Volatility downloaded'
unzip 2.5.zip &>> $logfile
cd volatility-2.5 &>> $logfile
python setup.py build &>> $logfile
python setup.py install &>> $logfile
error_check 'Volatility installed'
fi

##MITMProxy
if [ ! -f /usr/local/bin/mitmproxy ]; then
print_status "${YELLOW}Installing MITM${NC}"
apt-get install python3-dev python3-pip libffi-dev libssl-dev -y &>> $logfile
pip3 install mitmproxy &>> $logfile
error_check 'MITM installed'
fi

##Suricata
if [ ! -f /etc/suricata/rules/cuckoo.rules ]; then
cd $gitdir
print_status "${YELLOW}Setting up Suricata${NC}"
touch /etc/suricata/rules/cuckoo.rules &>> $logfile
echo "alert http any any -> any any (msg:\"FILE store all\"; filestore; noalert; sid:15; rev:1;)"  | sudo tee /etc/suricata/rules/cuckoo.rules &>> $logfile
chown $name:$name /etc/suricata/suricata.yaml &>> $logfile
fi

##etupdate
if [ ! -f /usr/sbin/etupdate ]; then
cd $gitdir
git clone https://github.com/seanthegeek/etupdate &>> $logfile
cd etupdate
mv etupdate /usr/sbin/
/usr/sbin/etupdate -V &>> $logfile
error_check 'Suricata updateded'
chown $name:$name /usr/sbin/etupdate &>> $logfile
chown -R $name:$name /etc/suricata/rules &>> $logfile
crontab -u $name $gitdir/lib/cron  
cp $gitdir/lib/suricata-cuckoo.yaml /etc/suricata/suricata.yaml
error_check 'Suricata configured for auto-update'
fi

##Snort
#print_status "${YELLOW}Setting up Snort${NC}"
#cd $gitdir
#if [ ! -f /usr/local/bin/daq-modules-config ]; then
#wget https://www.snort.org/downloads/snort/daq-2.0.6.tar.gz &>> $logfile
#tar -zxvf daq-2.0.6.tar.gz &>> $logfile
#cd daq*  &>> $logfile
#./configure &>> $logfile
#make  &>> $logfile
#make install  &>> $logfile
#error_check 'DAQ installed'
#fi
#cd $gitdir
#if [ ! -f /usr/sbin/snort ]; then
#apt-get install snort -y
#rm /etc/snort/snort.conf
#cp $gitdir/lib/snort.conf /etc/snort/
##wget https://www.snort.org/downloads/snort/snort-2.9.9.0.tar.gz  &>> $logfile
##tar -xvzf snort-2.9.9.0.tar.gz  &>> $logfile
##cd snort*
##./configure --enable-sourcefire &>> $logfile
##make &>> $logfile
##make install  &>> $logfile
##error_check 'Snort installed'
##ldconfig  &>> $logfile
##ln -s /usr/local/bin/snort /usr/sbin/snort  &>> $logfile
##groupadd snort  &>> $logfile 
##sudo useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort  &>> $logfile
##mkdir -p /etc/snort/rules/iplists  &>> $logfile
##mkdir /etc/snort/preproc_rules &>> $logfile
##mkdir /usr/local/lib/snort_dynamicrules &>> $logfile
##mkdir /etc/snort/so_rules &>> $logfile
##mkdir -p /var/log/snort/archived_logs &>> $logfile
##touch /etc/snort/rules/iplists/black_list.rules &>> $logfile
##touch /etc/snort/rules/iplists/white_list.rules &>> $logfile
##touch /etc/snort/rules/local.rules &>> $logfile
##touch /etc/snort/rules/snort.rules &>> $logfile
##touch /etc/snort/sid-msg.map &>> $logfile
#chmod -R 5777 /etc/snort &>> $logfile
#chmod -R 5777 /var/log/snort &>> $logfile
#chmod -R 5777 /usr/local/lib/snort_dynamicrules &>> $logfile
##chown -R snort:snort /etc/snort &>> $logfile
#chown -R $name:$name /var/log/snort &>> $logfile
##chown -R snort:snort /usr/local/lib/snort_dynamicrules &>> $logfile
##cd $gitdir/snort-*/etc/ &>> $logfile
##cp *.conf* /etc/snort &>> $logfile
##cp *.map /etc/snort &>> $logfile
##cp *.dtd /etc/snort &>> $logfile
##cd $gitdir/snort-*/src/dynamic-preprocessors/build/usr/local/lib/snort_dynamicpreprocessor/ &>> $logfile
##cp * /usr/local/lib/snort_dynamicpreprocessor/ &>> $logfile
##cp $gitdir/lib/snort.conf /etc/snort/ &>> $logfile
##error_check 'Snort configured'
#fi

###Pulledpork
#if [ ! -f /usr/local/bin/pulledpork.pl ]; then
#cd $gitdir
#git clone https://github.com/shirkdog/pulledpork.git &>> $logfile
#cd pulledpork &>> $logfile
#sudo cp pulledpork.pl /usr/local/bin/ &>> $logfile
#chmod +x /usr/local/bin/pulledpork.pl &>> $logfile
#cp etc/*.conf /etc/snort/ &>> $logfile
#cp $gitdir/lib/pulledpork.conf /etc/snort/ &>> $logfile
#sed -ie "s/<oinkcode>/$oinkcode/g" /etc/snort/pulledpork.conf
#/usr/local/bin/pulledpork.pl -c /etc/snort/pulledpork.conf -l &>> $logfile
#cp  $gitdir/lib/snort.service /lib/systemd/system/ &>> $logfile
#systemctl enable snort &>> $logfile
#systemctl start snort &>> $logfile
#error_check 'Pulledpork installed'
#fi

##MySQL install
if [ "$mysql_check" == "true" ] && [ "$mysqlconf_check" == "true" ]; then
print_status "${YELLOW}MySQL installed, skipping installation${NC}"
else
print_status "${YELLOW}Installing MySQL${NC}"
debconf-set-selections <<< "mysql-server mysql-server/$root_mysql_pass password root" &>> $logfile
debconf-set-selections <<< "mysql-server mysql-server/$root_mysql_pass password root" &>> $logfile
error_check 'MySQL passwords set' 
print_status "${YELLOW}Downloading and installing MySQL${NC}"
apt-get -y install mysql-server python-mysqldb &>> $logfile 
error_check 'MySQL installed'
print_status "${YELLOW}Configuring MySQL${NC}"
mysql -uroot -p$root_mysql_pass -e "DELETE FROM mysql.user WHERE User=''; DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1'); DROP DATABASE IF EXISTS test; DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'; DROP DATABASE IF EXISTS cuckoo; CREATE DATABASE cuckoo; GRANT ALL PRIVILEGES ON cuckoo.* TO 'cuckoo'@'localhost' IDENTIFIED BY '$cuckoo_mysql_pass'; FLUSH PRIVILEGES;" &>> $logfile
error_check 'MySQL secure installation and cuckoo database/user creation'
replace "connection =" "connection = mysql://cuckoo:$cuckoo_mysql_pass@localhost/cuckoo" -- /home/$name/conf/cuckoo.conf &>> $logfile
error_check 'Configuration files modified'
fi

##Other tools
cd /home/$name/tools/
print_status "${YELLOW}Waiting for dpkg process to free up...${NC}"
print_status "${YELLOW}If this takes too long try running ${RED}sudo rm -f /var/lib/dpkg/lock${YELLOW} in another terminal window.${NC}"
while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
   sleep 1
done
print_status "${YELLOW}Installing additional tools${NC}"
cd $gitdir
sudo -H pip install git+https://github.com/buffer/pyv8 &>> $logfile
print_status "${YELLOW}Installing antivmdetect${NC}"
##Folder setup
dir_check /usr/bin/cd-drive
##Antivm download
git clone https://github.com/benrau87/antivmdetect.git  &>> $logfile
error_check 'Antivm tools downloaded'

##Guacamole Setup
print_status "${YELLOW}Installing Gucamole..${NC}"
mkdir /tmp/guac-build && cd /tmp/guac-build  &>> $logfile
wget https://www.apache.org/dist/guacamole/0.9.14/source/guacamole-server-0.9.14.tar.gz  &>> $logfile
tar xvf guacamole-server-0.9.14.tar.gz  &>> $logfile
cd guacamole-server-0.9.14  &>> $logfile
./configure --with-init-dir=/etc/init.d  &>> $logfile
make && make install && cd ..  &>> $logfile
ldconfig  &>> $logfile
etc/init.d/guacd start  &>> $logfile
error_check 'Guacamole installed'

##TOR
print_status "${YELLOW}Installing Tor..${NC}"
apt-get install tor deb.torproject.org-keyring -f -y &>> $logfile
echo "TransPort 192.168.56.1:9040" | tee -a /etc/tor/torrc
echo "DNSPort 192.168.56.1:5353" | tee -a /etc/tor/torrc
error_check 'Tor installed'

##Holding pattern for dpkg...
print_status "${YELLOW}Waiting for dpkg process to free up...${NC}"
print_status "${YELLOW}If this takes too long try running ${RED}sudo rm -f /var/lib/dpkg/lock${YELLOW} in another terminal window.${NC}"
while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
   sleep 1
done

##Permissions
print_status "${YELLOW}Setting tcpdump vbox permissions${NC}"
setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump &>> $logfile
aa-disable /usr/sbin/tcpdump &>> $logfile
usermod -a -G vboxusers $name &>> $logfile
error_check 'Permissions set'

###Setup of VirtualBox forwarding rules and host only adapter
echo 1 | sudo tee -a /proc/sys/net/ipv4/ip_forward &>> $logfile
sysctl -w net.ipv4.ip_forward=1 &>> $logfile

##Rooter
print_status "${YELLOW}Adding route commands and crons${NC}"
echo "400    $interface" | tee -a /etc/iproute2/rt_tables &>> $logfile
systemctl enable rc-local &>> $logfile
cp $gitdir/lib/threshold.config /etc/suricata/
error_check "Routing configured"

##Cuckoo Web and first run
print_status "${YELLOW}Setting up Cuckoo signatures${NC}"
sudo -i -u $name cuckoo &
sleep 20
sudo -i -u $name cp /home/$name/conf/* /home/$name/.cuckoo/conf
sudo -i -u $name cuckoo community

print_status "${YELLOW}Configuring webserver${NC}"
sudo adduser www-data $name  &>> $logfile

sudo -i -u $name cuckoo web --uwsgi | tee /tmp/cuckoo-web.ini  &>> $logfile
mv /tmp/cuckoo-web.ini /etc/uwsgi/apps-available/  &>> $logfile
ln -s /etc/uwsgi/apps-available/cuckoo-web.ini /etc/uwsgi/apps-enabled/  &>> $logfile

sudo -i -u $name cuckoo web --nginx | tee /tmp/cuckoo-web  &>> $logfile
mv /tmp/cuckoo-web /etc/nginx/sites-available/  &>> $logfile
sed -i -e 's/localhost/0.0.0.0/g' /etc/nginx/sites-available/cuckoo-web  &>> $logfile
ln -s /etc/nginx/sites-available/cuckoo-web /etc/nginx/sites-enabled/ &>> $logfile

sudo -i -u $name cuckoo api --uwsgi | tee /tmp/cuckoo-api.ini  &>> $logfile
mv /tmp/cuckoo-api.ini /etc/uwsgi/apps-available/  &>> $logfile
ln -s /etc/uwsgi/apps-available/cuckoo-api.ini /etc/uwsgi/apps-enabled/ &>> $logfile

sudo -i -u $name cuckoo api --nginx | tee /tmp/cuckoo-api &>> $logfile
mv /tmp/cuckoo-api /etc/nginx/sites-available/  &>> $logfile
sed -i -e 's/localhost/0.0.0.0/g' /etc/nginx/sites-available/cuckoo-api  &>> $logfile
ln -s /etc/nginx/sites-available/cuckoo-api /etc/nginx/sites-enabled/ &>> $logfile

service uwsgi restart  &>> $logfile
service nginx restart  &>> $logfile

print_status "${YELLOW}Installing vmcloak${NC}"
dir_check /mnt/windows_ISO &>> $logfile
dir_check /mnt/office_ISO &>> $logfile
apt-get install mkisofs genisoimage libffi-dev python-pip libssl-dev python-dev -y &>> $logfile
pip install vmcloak  &>> $logfile
pip install -U pytest pytest-xdist &>> $logfile
error_check 'Installed vmcloak'
print_status "${YELLOW}Updating Agent${NC}"
cp /home/$name/.cuckoo/agent/agent.py  /usr/local/lib/python2.7/dist-packages/vmcloak/data/bootstrap/ &>> $logfile
chown root:staff /usr/local/lib/python2.7/dist-packages/vmcloak/data/bootstrap/agent.py &>> $logfile

##Cleaup
print_status "${YELLOW}Doing some cleanup${NC}"
apt-get -y autoremove &>> $logfile && apt-get -y autoclean &>> $logfile
error_check "House keeping finished"
echo -e "${YELLOW}Installation complete, login as $name and open the terminal. Run restart_cuckoo.sh if needed. To get started as fast as possible you will need to create a VM with the vmcloak.sh script provided in your home directory. This will require you have a local copy of the Windows ISO you wish to use. You can then navigate to $HOSTNAME:8000 and submit samples.${NC}"

