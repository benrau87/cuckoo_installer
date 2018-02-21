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
cuckoo_yara=/home/steve/.cuckoo/yara
print_status "${YELLOW}Updating Cuckoo...Please Wait${NC}"
su - cuckoo -c 'cuckoo community' 
##Critical Stack
#print_status "${YELLOW}Updating Critical Stack...Please Wait${NC}"
#critical-stack-intel pull 
#CS_RULES=/opt/critical-stack/frameworks/intel/master-public.bro.dat
#SURI_RULE_FILE=/etc/suricata/rules/cuckoo.rules
#BL2=/opt/bl2ru2/bl2ru2/bl2ru2.py
#rm $SURI_RULE_FILE
#touch $SURI_RULE_FILE
#awk '/ /{print $2 " " "Critical_Stack_Intel" " " $1}' $CS_RULES > /tmp/rules.list
#$BL2 /tmp/rules.list -o $SURI_RULE_FILE
##Update Yara sigsnatures
print_status "${YELLOW}Updating Yara...Please Wait${NC}"
cd /tmp
rm -rf rules/
git clone https://github.com/Yara-Rules/rules
cd rules
cp CVE_Rules/* $cuckoo_yara/binaries
cp Crypto/* $cuckoo_yara/binaries
cp malware/* $cuckoo_yara/binaries
cp Packers/* $cuckoo_yara/binaries
#Rulz that dont play well
rm $cuckoo_yara/binaries/MALW_AZORULT.yar
##Update IDS signatures
print_status "${YELLOW}Updating Suricata...Please Wait${NC}"
etupdate -V 
service suricata restart
print_status "${GREEN}You are now too legit 2 quit!${NC}"
