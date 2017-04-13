
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
########################################
##BEGIN MAIN SCRIPT##
#Pre checks: These are a couple of basic sanity checks the script does before proceeding.
echo -e "${YELLOW}What is your Cuckoo account username?${NC}"
read name

chmod +x start_cuckoo.sh
chown $name:$name start_cuckoo.sh
mv start_cuckoo.sh /home/$name/

print_status "${YELLOW}Downloading Cuckoo${NC}"
git clone https://github.com/cuckoosandbox/cuckoo.git  &>> $logfile
error_check 'Cuckoo downloaded'
cp -rf $gitdir/conf/ cuckoo/
chown -R $name:$name cuckoo
mv cuckoo /etc/

##Holding pattern for dpkg...
print_status "${YELLOW}Waiting for dpkg process to free up...${NC}"
print_status "${YELLOW}If this takes too long try running ${RED}sudo rm -f /var/lib/dpkg/lock${YELLOW} in another terminal window.${NC}"
while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
   sleep 1
done

print_status "${YELLOW}Downloading and installing depos${NC}"
apt-get install -y build-essential checkinstall &>> $logfile
chmod u+rwx /usr/local/src &>> $logfile
apt-get install -y linux-headers-$(uname -r) &>> $logfile
apt-get install -y libpcre++-dev uthash-dev libarchive-dev tesseract-ocr libelf-dev libssl-dev libgeoip-dev &>> $logfile
pip install m2crypto &>> $logfile
error_check 'Depos installed'

print_status "${YELLOW}Downloading and installing DTrace${NC}"
cd /etc
git clone https://github.com/dtrace4linux/linux.git dtrace &>> $logfile
cd dtrace
bash tools/get-deps.pl -y &>> $logfile
make all &>> $logfile
make install &>> $logfile
make load &>> $logfile
error_check 'DTrace installed'

print_status "${YELLOW}Installing MitM proxy${NC}"
cd ~
apt-get install -y mitmproxy &>> $logfile
error_check 'MitM proxy installed'
print_status "${YELLOW}Installing MitM proxy certs for cuckoo${NC}"
mitmproxy & 
cp ~/.mitmproxy/mitmproxy-ca-cert.p12 /etc/cuckoo/analyzer/windows/bin/cert.p12 &>> $logfile
cp ~/.mitmproxy/mitmproxy-ca-cert.p12 /home/$name/tools/

print_status "${YELLOW}Installing Snort${NC}"
apt-get install snort -qq
chmod -Rv 777 /etc/snort/
chmod -Rv 777 /var/log/snort/
error_check 'Snort Installed'


print_status "${YELLOW}Adding Sudo Access to Rooter${NC}"
echo "$name ALL=(ALL) NOPASSWD: /usr/bin/python /etc/cuckoo/utils/rooter.py" >> /etc/sudoers &>> $logfile
error_check 'Command Added, please restart to finish installation"
