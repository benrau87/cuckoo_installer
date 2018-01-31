#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
exit 1
fi
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
gitdir=$PWD

##Logging setup
logfile=/var/log/vmcloak_install.log
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

############################################################################################################################
############################################################################################################################
############################################################################################################################
############################################################################################################################
RANGE=255
number=$RANDOM
numbera=$RANDOM
numberb=$RANDOM
let "number %= $RANGE"
let "numbera %= $RANGE"
let "numberb %= $RANGE"
octets='0019eC'
octeta=`echo "obase=16;$number" | bc`
octetb=`echo "obase=16;$numbera" | bc`
octetc=`echo "obase=16;$numberb" | bc`
macadd="${octets}${octeta}${octetb}${octetc}"

dir_check /mnt/windows_ISOs &>> $logfile

echo -e "${RED}Active interfaces${NC}"
for iface in $(ifconfig | cut -d ' ' -f1| tr '\n' ' ')
do 
  addr=$(ip -o -4 addr list $iface | awk '{print $4}' | cut -d/ -f1)
  printf "$iface\t$addr\n"
done
echo -e "${YELLOW}What is the name of the interface which has an internet connection?(ex: eth0)${NC}"
read interface
echo -e "${YELLOW}What is the name for the Cuckoo user on this machine?${NC}"
read user
echo -e "${YELLOW}What is the IP you would like to use for this machine (must be between 192.168.56.100-200)?${NC}"
read ip
echo -e "${YELLOW}How much RAM would you like to allocate for this machine?${NC}"
read ram
echo -e "${YELLOW}How many CPU cores would you like to allocate for this machine?${NC}"
read cpu
echo -e "${YELLOW}What is the distro? (winxp, win7x86, win7x64, win81x86, win81x64, win10x86, win10x64)${NC}"
read distro
echo -e "${YELLOW}Enter in a serial key now if you would like to be legit, otherwise you can skip this for now.${NC}"
read serial
echo -e "${YELLOW}What is the name for this machine?${NC}"
read name
echo
read -n 1 -s -p "Please place your Windows ISO in the folder under /mnt/windows_ISOs and press any key to continue"
echo
print_status "${YELLOW}Mounting ISO if needed${NC}"
mkdir  /mnt/$name &>> $logfile
mount -o loop,ro /mnt/windows_ISOs/* /mnt/$name &>> $logfile
error_check 'Mounted ISO'

print_status "${YELLOW}Installing genisoimage${NC}"
apt-get install mkisofs genisoimage libffi-dev python-pip libssl-dev python-dev -y &>> $logfile
error_check 'Prereqs installed'

if [ ! -d "/usr/local/bin/vmcloak" ]; then
print_status "${YELLOW}Installing vmcloak${NC}"
pip install vmcloak  &>> $logfile
pip install -U pytest pytest-xdist &>> $logfile
error_check 'Installed vmcloak'
fi

print_status "${YELLOW}Checking for host only interface${NC}"
VBoxManage hostonlyif create
#VBoxManage hostonlyif ipconfig vboxnet0 --ip 10.1.1.254
VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1
#vmcloak-iptables 10.1.1.0/24 $interface
vmcloak-iptables 192.168.56.0/24 $interface

echo -e "${YELLOW}Creating VM, some interaction may be required${NC}"
#if [ -z "$serial" ]
#then
#VBoxManage hostonlyif ipconfig vboxnet0 --ip 10.1.1.254
su - $user -c "vmcloak init --$distro --vm-visible --ramsize $ram --cpus $cpu --iso-mount /mnt/$name $name" &>> $logfile
#su - $user -c "vmcloak init --$distro --vm-visible --ip $ip --gateway 10.1.1.254 --netmask 255.255.255.0 --ramsize $ram --cpus $cpu --iso-mount /mnt/$name $name" &>> $logfile
#su - $user -c "vmcloak init --$distro --vm-visible --ip $ip --gateway 192.168.56.1 --netmask 255.255.255.0 --ramsize $ram --cpus $cpu --iso-mount /mnt/$name $name" &>> $logfile

error_check 'Created VM'
#else
#su - $user -c "vmcloak init --$distro --serial-key $serial --vm-visible --ip $ip --gateway 10.1.1.254 --netmask 255.255.255.0 --ramsize $ram --cpus $cpu --iso-mount /mnt/$name $name" &>> $logfile
#error_check 'Created VM'
#fi
#VBoxManage hostonlyif ipconfig vboxnet0 --ip 10.1.1.254
echo -e "${YELLOW}Installing programs on VM, some interaciton may be required${NC}"
su - $user -c "vmcloak install $name --vm-visible wallpaper adobe9 flash wic python27 pillow dotnet java removetooltips wallpaper chrome winrar ie11" 
error_check 'Installed adobe9 wic pillow dotnet40 java7 removetooltips on VMs'

echo -e "${YELLOW}Starting VM and creating a running snapshot...Please wait.${NC}"  
su - $user -c "vmcloak snapshot $name $name" &>> $logfile
error_check 'Created snapshot'

echo
echo -e "${YELLOW}The VM is located under your user $user home folder under .vmcloak, you will need to register this with Virtualbox on your cuckoo account.${NC}"  

