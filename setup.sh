
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
rm -rf /home/$name/tools/*
cd tools/

###Add Repos
##Mongodb
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6 &>> $logfile
echo "deb [ arch=amd64,arm64 ] http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.4.list &>> $logfile
error_check 'Mongodb added'

##Elasticsearch
add-apt-repository ppa:webupd8team/java -y &>> $logfile
error_check 'Java Repo added'
wget -qO - https://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -
add-apt-repository "deb http://packages.elasticsearch.org/elasticsearch/1.4/debian stable main" &>> $logfile
error_check 'Elasticsearch Repo added'

##Suricata
add-apt-repository ppa:oisf/suricata-beta -y &>> $logfile
error_check 'Suricata Repo added'

##Move Start Script
chmod +x $gitdir/supporting_scripts/start_cuckoo.sh
chown $name:$name $gitdir/supporting_scripts/start_cuckoo.sh
mv $gitdir/supporting_scripts/start_cuckoo.sh /home/$name/

##Start mongodb 
chmod 755 $gitdir/lib/mongodb.service
cp $gitdir/lib/mongodb.service /etc/systemd/system/

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
apt-get install -y dh-autoreconf libpcre++-dev uthash-dev libarchive-dev tesseract-ocr libelf-dev libssl-dev libgeoip-dev -y &>> $logfile
apt-get install python python-pip python-dev libffi-dev libssl-dev libpq-dev -y
apt-get install python-virtualenv python-setuptools -y
apt-get install libjpeg-dev zlib1g-dev swig mongodb virtualbox -y
error_check 'Depos installed'

print_status "${YELLOW}Downloading and installing Cuckoo${NC}"
pip install -U pip setuptools  &>> $logfile
pip install -U cuckoo &>> $logfile
error_check 'Cuckoo downloaded and installed'

##Java install for elasticsearch
print_status "${YELLOW}Installing Java${NC}"
echo debconf shared/accepted-oracle-license-v1-1 select true | \
  sudo debconf-set-selections &>> $logfile
apt-get install oracle-java7-installer -y &>> $logfile
error_check 'Java Installed'

##Setup Elasticsearch
print_status "${YELLOW}Setting up Elasticsearch${NC}"
update-rc.d elasticsearch defaults 95 10 &>> $logfile
/etc/init.d/elasticsearch start &>> $logfile
service elasticsearch start &>> $logfile

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

##MitM
print_status "${YELLOW}Installing MitM proxy${NC}"
cd ~
apt-get install -y mitmproxy &>> $logfile
print_status "${YELLOW}Installing MitM proxy certs for cuckoo${NC}"
mitmproxy & 
cp ~/.mitmproxy/mitmproxy-ca-cert.p12 /etc/cuckoo/analyzer/windows/bin/cert.p12 &>> $logfile
cp ~/.mitmproxy/mitmproxy-ca-cert.p12 /home/$name/tools/ &>> $logfile
error_check 'MitM proxy installed'

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
cp $gitdir/lib/suricata-cuckoo.yaml /etc/suricata/
git clone https://github.com/seanthegeek/etupdate &>> $logfile
cd etupdate
mv etupdate /usr/sbin/
/usr/sbin/etupdate -V &>> $logfile
error_check 'Suricata updateded'
chown $name:$name /usr/sbin/etupdate &>> $logfile
chown -R $name:$name /etc/suricata/rules &>> $logfile
crontab -u $name $gitdir/lib/cron 
error_check 'Suricata configured for auto-update'

##Snort
print_status "${YELLOW}Installing Snort${NC}"
apt-get install snort -qq
chmod -Rv 777 /etc/snort/
chmod -Rv 777 /var/log/snort/
error_check 'Snort Installed'

##Other tools
cd /home/$name/tools/
print_status "${YELLOW}Grabbing other tools${NC}"
apt-get install libboost-all-dev -y &>> $logfile
sudo -H pip install git+https://github.com/buffer/pyv8 &>> $logfile
error_check 'PyV8 installed'

##Rooter
print_status "${YELLOW}Adding Sudo Access to Rooter${NC}"
echo "$name ALL=(ALL) NOPASSWD: /usr/bin/python /etc/cuckoo/utils/rooter.py" >> /etc/sudoers &>> $logfile
error_check 'Command Added, please restart to finish installation"
