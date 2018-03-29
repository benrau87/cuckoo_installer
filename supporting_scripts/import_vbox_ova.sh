#!/bin/bash

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
gitdir=$PWD

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

############################################################################################################################
############################################################################################################################
############################################################################################################################
############################################################################################################################
hexchars="0123456789ABCDEF"
end=$( for i in {1..6} ; do echo -n ${hexchars:$(( $RANDOM % 16 )):1} ; done | sed -e 's/\(..\)/\1/g' )
macadd="0019EC$end"

if [ "$t1" = "$t2" ]; then
  VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 &>> $logfile
else
  VBoxManage hostonlyif create &>> $logfile
  VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 &>> $logfile
fi

vmcloak-iptables 192.168.56.0/24 ens160

if [ "$#" -eq 0 ];then
	echo "Enter the name of the .ova to import "
        exit
	else
	ova=$1
fi

if [ ! -f $ova ];then
	echo "$1 does not exist, are you using the full path?"
	exit
fi
echo -e "${YELLOW}What is the name for this machine?${NC}"
read name
echo -e "${YELLOW}What RDP port would you like to assign this machine?${NC}"
read rdp
echo -e "${YELLOW}What IP would you like to assign this machine?${NC}"
read ip
VBoxManage import $ova --vsys 0 --vmname $name
echo -e "${YELLOW}Setting up machine machine${NC}"
VBoxManage modifyvm $name --macaddress1	$macadd
VBoxManage modifyvm $name --vrde on
VBoxManage modifyvm $name --vrdeport $rdp
echo -e "${YELLOW}Starting VM and waiting for response...${NC}"
VBoxManage startvm $name --type headless
read -n 1 -s -p "VM started, you can RDP to the running box at port $rdp, MAKE SURE TO ASSIGN THE IP $ip, make any changes, hit ENTER to take a snapshot and shutdown the machine."
echo
VBoxManage snapshot $name take vmcloak_modified --live
VBoxManage controlvm $name poweroff
echo -e "${YELLOW}Registering machine with Cuckoo...${NC}"
cuckoo machine --add $name $ip --platform windows --snapshot vmcloak_modified
echo -e "${YELLOW}Adding baseline process, this will be ran when you first start cuckoo${NC}"
echo
cuckoo submit --machine $name --baseline
echo -e "${YELLOW}VM creation completed!${NC}"
