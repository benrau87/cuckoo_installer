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
##Binary based rules
cp rules/CVE_Rules/*.yar $cuckoo_yara/binaries/
cp rules/malware/*.yar $cuckoo_yara/binaries/
cp rules/Crypto/*.yar $cuckoo_yara/binaries/
cp rules/utils/*.yar $cuckoo_yara/binaries/
cp rules/Malicious_Documents/*.yar $cuckoo_yara/binaries/
cp rules/Packers/*.yar $cuckoo_yara/binaries/
cp rules/email/*.yar $cuckoo_yara/binaries/
A=("include)
B="$(ls $cuckoo_yara/binaries/)"
C=(")
echo ${A[@]}$B${C[@]}

##URL based rules
cp rules/Webshells/*.yar $cuckoo_yara/urls/
echo '"include $cuckoo_yara/urls/$(ls $cuckoo_yara/urls/)"' > index_urls.yar
for rule in $(ls $cuckoo_yara/urls/)
do 
echo '"include' $cuckoo_yara/urls/$rule'"'
done
##Remove shitty rules
rm $cuckoo_yara/binaries/Android*  
rm $cuckoo_yara/binaries/antidebug_antivm.yar  
rm $cuckoo_yara/binaries/MALW_AdGholas.yar  
rm $cuckoo_yara/binaries/APT_Shamoon*.yar  
rm $cuckoo_yara/binaries/peid.yar  

print_status "${YELLOW}Updating Suricata...Please Wait${NC}"
etupdate -V 
service suricata restart
print_status "${YELLOW}Updating Snort...Please Wait${NC}"
pulledpork.pl -c /etc/snort/pulledpork.conf 
service snort restart &>> $logfile
print_status "${GREEN}You are now too legit 2 quit!${NC}"
