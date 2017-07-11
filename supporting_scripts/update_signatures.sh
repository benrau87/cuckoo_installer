#!/bin/bash
####################################################################################################################

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
GREEN='\033[1;32m'
gitdir=$PWD

##Logging setup
logfile=/var/log/update_cuckoo_sigs.log
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
###Cuckoo Modules
cuckoo_yara=/home/cuckoo/.cuckoo/yara
print_status "${YELLOW}Updating Cuckoo...Please Wait${NC}"
su - cuckoo -c 'cuckoo community' 
###YARA
print_status "${YELLOW}Updating Yara...Please Wait${NC}"
cd $cuckoo_yara
rm -rf rules/
git clone https://github.com/yara-rules/rules.git &>> $logfile

##Copy rules
#Bins
#cp rules/CVE_Rules/*.yar $cuckoo_yara/binaries/
#cp rules/malware/*.yar $cuckoo_yara/binaries/
cp rules/Crypto/*.yar $cuckoo_yara/binaries/
cp rules/utils/*.yar $cuckoo_yara/binaries/
#cp rules/Malicious_Documents/*.yar $cuckoo_yara/binaries/
#cp rules/Packers/*.yar $cuckoo_yara/binaries/
#cp rules/email/*.yar $cuckoo_yara/binaries/
##Remove shitty rules
#rm $cuckoo_yara/binaries/Android*   &>> $logfile
#rm $cuckoo_yara/binaries/antidebug_antivm.yar   &>> $logfile
#rm $cuckoo_yara/binaries/MALW_AdGholas.yar   &>> $logfile
#rm $cuckoo_yara/binaries/APT_Shamoon*.yar   &>> $logfile
#rm $cuckoo_yara/binaries/peid.yar   &>> $logfile
#Urls
#cp $cuckoo_yara/binaries/url.yar $cuckoo_yara/urls/
#cp $cuckoo_yara/binaries/ip.yar $cuckoo_yara/urls/
#cp $cuckoo_yara/binaries/urls.yar $cuckoo_yara/urls/
#cp rules/Webshells/*.yar $cuckoo_yara/urls/
#Mem
cp rules/Crypto/*.yar $cuckoo_yara/memory/
cp rules/utils/*.yar $cuckoo_yara/memory/
cp $cuckoo_yara/binaries/url.yar $cuckoo_yara/memory/
cp $cuckoo_yara/binaries/ip.yar $cuckoo_yara/memory/
cp $cuckoo_yara/binaries/urls.yar $cuckoo_yara/memory/
#cp rules/malware/*.yar $cuckoo_yara/memory/

##Create Index
#Binaries
#ls -d $cuckoo_yara/binaries/*.yar | awk '{print "include \"" $0 "\""}' | tee $cuckoo_yara/index_binaries.yar &>> $logfile
##URLs
#ls -d $cuckoo_yara/urls/*.yar | awk '{print "include \"" $1 "\""}' |  tee $cuckoo_yara/index_urls.yar &>> $logfile
##Memory
#ls -d $cuckoo_yara/memory/*.yar | awk '{print "include \"" $1 "\""}' |  tee $cuckoo_yara/index_memory.yar &>> $logfile

##Update IDS signatures
print_status "${YELLOW}Updating Suricata...Please Wait${NC}"
etupdate -V 
service suricata restart
print_status "${YELLOW}Updating Snort...Please Wait${NC}"
pulledpork.pl -c /etc/snort/pulledpork.conf 
service snort restart &>> $logfile
print_status "${GREEN}You are now too legit 2 quit!${NC}"
