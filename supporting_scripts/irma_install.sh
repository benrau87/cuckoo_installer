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
logfile=/var/log/irma_install.log
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

#Checks
if [ "$(lscpu | grep VT-x | wc -l)" != "1" ]; then
	echo -e "${YELLOW}You cannot install 64-bit VMs or IRMA on this machine due to VT-x instruction set missing${NC}"
	exit
else
	vtx=true
fi	
##IRMA
if [ "$vtx" == "true" ]; then
	print_status "${YELLOW}Setting up IRMA${NC}"
	cd $gitdir
	#wget https://releases.hashicorp.com/vagrant/1.9.7/vagrant_1.9.7_x86_64.deb?_ga=2.3815416.933420289.1499534277-1169717771.1499534277 &>> $logfile
	#dpkg -i vagrant* &>> $logfile
	git clone https://github.com/quarkslab/irma &>> $logfile
	cd irma/ansible/ &>> $logfile
	pip install -r requirements.txt
	ansible-galaxy install -r ansible-requirements.yml --force &>> $logfile
	print_status "${YELLOW}Setting up IRMA VM, this can take up to 30 mins.${NC}"
	vagrant up &>> $logfile
	error_check 'IRMA Installed'
	echo "172.16.1.30    www.frontend.irma" | tee -a /etc/hosts &>> $logfile
	error_check 'IRMA installed'
else
	print_status "${YELLOW}Skipping setup of IRMA due to hardware constraints${NC}"
fi
