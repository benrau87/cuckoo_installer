
#!/bin/bash

###Change these as needed and save them securely somewhere! Only needed if you plan on using MySQL##################
root_mysql_pass='w4ndZrsM2H_K4FjqSaog4_jWg'
cuckoo_mysql_pass='DuZXb7K7cldzU5DS5Q5lVzaay'

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
########################################
##BEGIN MAIN SCRIPT##
#Pre checks: These are a couple of basic sanity checks the script does before proceeding.
##Depos add
#this is a nice little hack I found in stack exchange to suppress messages during package installation.
export DEBIAN_FRONTEND=noninteractive

##Cuckoo user account
echo -e "${YELLOW}We need to create a local account to run your Cuckoo sandbox from; What would you like your Cuckoo account username to be?${NC}"
read name
adduser $name --gecos ""

##Create directories for later
cd /home/$name/
dir=$PWD
dir_check /home/$name/tools
dir_check /home/$name/conf
cp $gitdir/conf/* /home/$name/conf
cp $gitdir/supporting_scripts/firstrun.sh /home/$name/
chown $name:$name -R /home/$name/conf
chown $name:$name -R /home/$name/firstrun.sh
chmod +x /home/$name/firstrun.sh
rm -rf /home/$name/tools/*
cd tools/

###Add Repos
##Mongodb
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6 &>> $logfile
echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list &>> $logfile
error_check 'Mongodb added'

##Java
add-apt-repository ppa:webupd8team/java -y &>> $logfile
error_check 'Java Repo added'

##Elasticsearch
wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add - &>> $logfile
echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | tee /etc/apt/sources.list.d/elasticsearch-2.x.list &>> $logfile
error_check 'Elasticsearch Repo added'

##Suricata
add-apt-repository ppa:oisf/suricata-beta -y &>> $logfile
error_check 'Suricata Repo added'

####End of repos


##Move Start Script
chmod +x $gitdir/supporting_scripts/start_cuckoo.sh
chown $name:$name $gitdir/supporting_scripts/start_cuckoo.sh
mv $gitdir/supporting_scripts/start_cuckoo.sh /home/$name/


##Holding pattern for dpkg...
print_status "${YELLOW}Waiting for dpkg process to free up...${NC}"
print_status "${YELLOW}If this takes too long try running ${RED}sudo rm -f /var/lib/dpkg/lock${YELLOW} in another terminal window.${NC}"
while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
   sleep 1
done

# System updates
print_status "${YELLOW}Performing apt-get update and upgrade (May take a while if this is a fresh install)..${NC}"
apt-get update &>> $logfile && apt-get -y upgrade &>> $logfile
error_check 'Updated system'


##Main Packages
print_status "${YELLOW}Downloading and installing depos${NC}"
apt-get install -y build-essential checkinstall &>> $logfile
chmod u+rwx /usr/local/src &>> $logfile
apt-get install -y linux-headers-$(uname -r) &>> $logfile
apt-get install -y dh-autoreconf libjansson-dev libpcre++-dev uthash-dev libarchive-dev tesseract-ocr libelf-dev libssl-dev libgeoip-dev -y &>> $logfile
apt-get install python python-pip python-dev libffi-dev libssl-dev libpq-dev libmagic-dev python-sqlalchemy elasticsearch suricata  -y &>> $logfile
apt-get install python-virtualenv python-setuptools unattended-upgrades apt-listchanges fail2ban libfuzzy-dev bison byacc mitmproxy -y &>> $logfile
apt-get install libjpeg-dev zlib1g-dev swig virtualbox clamav clamav-daemon clamav-freshclam libconfig-dev flex mongodb-org -y &>> $logfile
apt-get install automake libtool make gcc libdumbnet-dev liblzma-dev libcrypt-ssleay-perl liblwp-useragent-determined-perl libpcap-dev -y  &>> $logfile
error_check 'Depos installed'

print_status "${YELLOW}Downloading and installing Cuckoo${NC}"
pip install -U pip setuptools &>> $logfile
pip install -U pip cuckoo &>> $logfile
pip install -U pip distorm3 &>> $logfile
pip install -U pip pycrypto &>> $logfile
pip install -U pip weasyprint &>> $logfile
pip install -U pip yara-python &>> $logfile
#cd ~
#wget https://github.com/cuckoosandbox/cuckoo/archive/2.0-rc1.zip &>> $logfile
#unzip 2.0-rc1.zip &>> $logfile
#mv cuckoo-* cuckoo
error_check 'Cuckoo downloaded and installed'

##Java install for elasticsearch
print_status "${YELLOW}Installing Java${NC}"
echo debconf shared/accepted-oracle-license-v1-1 select true | \
  sudo debconf-set-selections &>> $logfile
apt-get install oracle-java7-installer -y &>> $logfile
error_check 'Java Installed'

##Start mongodb 
print_status "${YELLOW}Setting up MongoDB${NC}"
chmod 755 $gitdir/lib/mongodb.service &>> $logfile
cp $gitdir/lib/mongodb.service /etc/systemd/system/ &>> $logfile
systemctl start mongodb &>> $logfile
systemctl enable mongodb &>> $logfile
error_check 'MongoDB Setup'

##Setup Elasticsearch
print_status "${YELLOW}Setting up Elasticsearch${NC}"
systemctl daemon-reload &>> $logfile
systemctl enable elasticsearch.service &>> $logfile
systemctl start elasticsearch.service &>> $logfile
error_check 'Elasticsearch Setup'

##Add user to vbox and enable mongodb
print_status "${YELLOW}Setting up Mongodb${NC}"
usermod -a -G vboxusers $name
systemctl start mongodb &>> $logfile
sleep 5
systemctl enable mongodb &>> $logfile
systemctl daemon-reload &>> $logfile
error_check 'Mongodb setup'

##Yara
cd /home/$name/tools/
print_status "${YELLOW}Downloading Yara${NC}"
#wget https://github.com/VirusTotal/yara/archive/v3.5.0.tar.gz &>> $logfile
git clone https://github.com/VirusTotal/yara.git &>> $logfile
error_check 'Yara downloaded'
#tar -zxf v3.5.0.tar.gz &>> $logfile
print_status "${YELLOW}Building and compiling Yara${NC}"
#cd yara-3.5.0
cd yara/
./bootstrap.sh &>> $logfile
./configure --with-crypto --enable-cuckoo --enable-magic &>> $logfile
error_check 'Yara compiled and built'
print_status "${YELLOW}Installing Yara${NC}"
make &>> $logfile
make install &>> $logfile
make check &>> $logfile
error_check 'Yara installed'

##tcpdump permissions
setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

##DTrace
print_status "${YELLOW}Downloading and installing DTrace${NC}"
cd /etc
git clone https://github.com/dtrace4linux/linux.git dtrace &>> $logfile
cd dtrace
bash tools/get-deps.pl -y &>> $logfile
make all &>> $logfile
make install &>> $logfile
make load &>> $logfile
error_check 'DTrace installed'

##Pydeep
cd /home/$name/tools/
print_status "${YELLOW}Setting up Pydeep${NC}"
sudo -H pip install git+https://github.com/kbandla/pydeep.git &>> $logfile
error_check 'Pydeep installed'

##Malheur
cd /home/$name/tools/
print_status "${YELLOW}Setting up Malheur${NC}"
git clone https://github.com/rieck/malheur.git &>> $logfile
error_check 'Malheur downloaded'
cd malheur
./bootstrap &>> $logfile
./configure --prefix=/usr &>> $logfile
make install &>> $logfile
error_check 'Malheur installed'

##Volatility
cd /home/$name/tools/
print_status "${YELLOW}Setting up Volatility${NC}"
git clone https://github.com/volatilityfoundation/volatility.git &>> $logfile
error_check 'Volatility downloaded'
cd volatility
python setup.py build &>> $logfile
python setup.py install &>> $logfile
error_check 'Volatility installed'


##Suricata
cd /home/$name/tools/
print_status "${YELLOW}Setting up Suricata${NC}"
#dir_check /etc/suricata/rules/cuckoo.rules
touch /etc/suricata/rules/cuckoo.rules &>> $logfile
echo "alert http any any -> any any (msg:\"FILE store all\"; filestore; noalert; sid:15; rev:1;)"  | sudo tee /etc/suricata/rules/cuckoo.rules &>> $logfile
git clone https://github.com/seanthegeek/etupdate &>> $logfile
cd etupdate
mv etupdate /usr/sbin/
/usr/sbin/etupdate -V &>> $logfile
error_check 'Suricata updateded'
chown $name:$name /usr/sbin/etupdate &>> $logfile
chown -R $name:$name /etc/suricata/rules &>> $logfile
crontab -u $name $gitdir/lib/cron  
cp $gitdir/lib/suricata-cuckoo.yaml /etc/suricata/
error_check 'Suricata configured for auto-update'

##Snort
print_status "${YELLOW}Setting up Snort${NC}"
cd $gitdir/
wget https://www.snort.org/downloads/snort/daq-2.0.6.tar.gz  &>> $logfile
tar -zxvf daq-2.0.6.tar.gz  &>> $logfile
cd daq*  &>> $logfile
./configure && make && make install  &>> $logfile
error_check 'DAQ installed'
wget https://www.snort.org/downloads/snort/snort-2.9.9.0.tar.gz  &>> $logfile
tar -xvzf snort-2.9.9.0.tar.gz  &>> $logfile
cd snort*
./configure --enable-sourcefire && make && make install  &>> $logfile
error_check 'Snort installed'
ldconfig  &>> $logfile
ln -s /usr/local/bin/snort /usr/sbin/snort  &>> $logfile
groupadd snort  &>> $logfile 
sudo useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort  &>> $logfile
mkdir -p /etc/snort/rules/iplists  &>> $logfile
mkdir -p /etc/snort/rules/iplists &>> $logfile
mkdir /etc/snort/preproc_rules &>> $logfile
mkdir /etc/snort/preproc_rules &>> $logfile
mkdir /usr/local/lib/snort_dynamicrules &>> $logfile
mkdir /usr/local/lib/snort_dynamicrules &>> $logfile
mkdir /etc/snort/so_rules &>> $logfile
mkdir /etc/snort/so_rules &>> $logfile
mkdir -p /var/log/snort/archived_logs &>> $logfile
mkdir -p /var/log/snort/archived_logs &>> $logfile
touch /etc/snort/rules/iplists/black_list.rules &>> $logfile
touch /etc/snort/rules/iplists/black_list.rules &>> $logfile
touch /etc/snort/rules/iplists/white_list.rules &>> $logfile
touch /etc/snort/rules/iplists/white_list.rules &>> $logfile
touch /etc/snort/rules/local.rules &>> $logfile
touch /etc/snort/rules/local.rules &>> $logfile
touch /etc/snort/sid-msg.map &>> $logfile
touch /etc/snort/sid-msg.map &>> $logfile
chmod -R 5775 /etc/snort &>> $logfile
chmod -R 5775 /var/log/snort &>> $logfile
chmod -R 5775 /var/log/snort &>> $logfile
chmod -R 5775 /usr/local/lib/snort_dynamicrules &>> $logfile
chmod -R 5775 /usr/local/lib/snort_dynamicrules &>> $logfile
chown -R snort:snort /etc/snort &>> $logfile
chown -R snort:snort /etc/snort &>> $logfile
chown -R snort:snort /var/log/snort &>> $logfile
chown -R snort:snort /var/log/snort &>> $logfile
chown -R snort:snort /usr/local/lib/snort_dynamicrules &>> $logfile
chown -R snort:snort /usr/local/lib/snort_dynamicrules &>> $logfile
cd snort_src/snort-*/etc/ &>> $logfile
cp *.conf* /etc/snort &>> $logfile
cp *.map /etc/snort &>> $logfile
cp *.dtd /etc/snort &>> $logfile
cd ~/snort_src/snort-*/src/dynamic-preprocessors/build/usr/local/lib/snort_dynamicpreprocessor/ &>> $logfile
cp * /usr/local/lib/snort_dynamicpreprocessor/ &>> $logfile
cp $gitdir/lib/snort.conf /etc/snort/ &>> $logfile
sed -i "s/include \$RULE\_PATH/#include \$RULE\_PATH/" /etc/snort/snort.conf &>> $logfile

##Pulledpork
git clone https://github.com/shirkdog/pulledpork.git &>> $logfile
cd pulledpork &>> $logfile
sudo cp pulledpork.pl /usr/local/bin/ &>> $logfile
chmod +x /usr/local/bin/pulledpork.pl &>> $logfile
cp etc/*.conf /etc/snort/ &>> $logfile
/usr/local/bin/pulledpork.pl -V &>> $logfile
cp $gitdir/lib/pulledpork.conf /etc/snort/ &>> $logfile
/usr/local/bin/pulledpork.pl -V &>> $logfile
/usr/local/bin/pulledpork.pl -c /etc/snort/pulledpork.conf -l &>> $logfile
cp  $gitdir/lib/snort.service /lib/systemd/system/ &>> $logfile
systemctl enable snort &>> $logfile
systemctl start snort &>> $logfile
error_check 'Pulledpork installed'

##Other tools
cd /home/$name/tools/
print_status "${YELLOW}Grabbing other tools${NC}"
apt-get install libboost-all-dev -y &>> $logfile
sudo -H pip install git+https://github.com/buffer/pyv8 &>> $logfile
error_check 'PyV8 installed'

##Holding pattern for dpkg...
print_status "${YELLOW}Waiting for dpkg process to free up...${NC}"
print_status "${YELLOW}If this takes too long try running ${RED}sudo rm -f /var/lib/dpkg/lock${YELLOW} in another terminal window.${NC}"
while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
   sleep 1
done


###Setup of VirtualBox forwarding rules and host only adapter
VBoxManage hostonlyif create
VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1
iptables -A FORWARD -o eth0 -i vboxnet0 -s 192.168.56.0/24 -m conntrack --ctstate NEW -j ACCEPT
sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A POSTROUTING -t nat -j MASQUERADE
sudo sysctl -w net.ipv4.ip_forward=1

read -p "Do you want to iptable changes persistent so that forwarding rules from the created subnet are applied at boot? This is highly recommended. Y/N" -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
echo
apt-get -qq install iptables-persistent -y &>> $logfile
error_check 'Persistent Iptable entries'
fi
echo


##MySQL install
read -p "Would you like to use a SQL database to support multi-threaded analysis? Y/N" -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
print_status "Setting ENV variables"
debconf-set-selections <<< "mysql-server mysql-server/$root_mysql_pass password root"
debconf-set-selections <<< "mysql-server mysql-server/$root_mysql_pass password root"
error_check 'MySQL passwords set'
print_status "Downloading and installing MySQL"
apt-get -y install mysql-server python-mysqldb &>> $logfile
error_check 'MySQL installed'
#mysqladmin -uroot password $root_mysql_pass &>> $logfile
#error_check 'MySQL root password change'	
mysql -uroot -p$root_mysql_pass -e "DELETE FROM mysql.user WHERE User=''; DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1'); DROP DATABASE IF EXISTS test; DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'; DROP DATABASE IF EXISTS cuckoo; CREATE DATABASE cuckoo; GRANT ALL PRIVILEGES ON cuckoo.* TO 'cuckoo'@'localhost' IDENTIFIED BY '$cuckoo_mysql_pass'; FLUSH PRIVILEGES;" &>> $logfile
error_check 'MySQL secure installation and cuckoo database/user creation'
replace "connection =" "connection = mysql://cuckoo:$cuckoo_mysql_pass@localhost/cuckoo" -- /home/$name/conf/cuckoo.conf &>> $logfile
error_check 'Configuration files modified'
fi

##Rooter
print_status "${YELLOW}Adding Sudo Access to Rooter${NC}"
echo "400    ens33" >> /etc/iproute2/rt_tables &>> $logfile
echo "/usr/local/bin/cuckoo rooter --sudo &" | tee -a /etc/rc.local &>> $logfile
systemctl enable rc-local &>> $logfile
#echo "401    eth0" >> /etc/iproute2/rt_tables &>> $logfile
error_check "Command Added, please restart to finish installation"

echo -e "${YELLOW}Installation complete, login as $name and open the terminal. Run the cuckoo command in the terminal to finish setup. Now copy the conf file in your ~ directory to ~/.cuckoo/conf/. In $name home folder you will find the start_cuckoo script. To get started as fast as possible you will need to create a virtualbox vm and name it ${RED}cuckoo1${NC}.${YELLOW} On the Windows VM install the windows_exes that can be found under the tools folder. Name the snapshot ${RED}vmcloak${YELLOW}. Alternatively you can create the VM with the vmcloak.sh script provided in your home directory. This will require you have a local copy of the Windows ISO you wish to use. You can then launch cuckoo_start.sh and navigate to $HOSTNAME:8000 or https://$HOSTNAME if Nginx was installed.${NC}"

