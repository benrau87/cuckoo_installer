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

print_status "${YELLOW}Installing genisoimage${NC}"
apt-get install mkisofs genisoimage libffi-dev python-pip libssl-dev -y &>> $logfile
error_check 'Prereqs installed'

dir_check /mnt/windows_ISOs &>> $logfile

if [ ! -d "/usr/local/bin/vmcloak" ]; then
print_status "${YELLOW}Installing vmcloak${NC}"
apt-get install build-essential libssl-dev libffi-dev -y
apt-get install python-dev genisoimage -y 
pip install vmcloak -y
error_check 'Installed vmcloak'
fi

print_status "${YELLOW}Checking for host only interface${NC}"
ON=$(ifconfig -a | grep -cs 'vboxnet0')
if [[ $ON == 1 ]]
then
  echo "Host only interface is up"
else 
VBoxManage hostonlyif create
VBoxManage hostonlyif ipconfig vboxnet0 --ip 10.1.1.254
fi


echo
read -n 1 -s -p "Please place your Windows ISO in the folder under /mnt/windows_ISOs and press any key to continue"
echo

#echo -e "${YELLOW}What is the Windows disto?"
#read distro
echo -e "${YELLOW}What is the name for the Cuckoo user on this machine?${NC}"
read user
echo -e "${YELLOW}What is the name for this machine?${NC}"
read name
echo -e "${YELLOW}How much RAM would you like to allocate for this machine?${NC}"
read ram
echo -e "${YELLOW}How many CPU cores would you like to allocate for this machine?${NC}"
read cpu
echo -e "${YELLOW}What is the distro? (winxp, win7x86, win7x64, win81x86, win81x64, win10x86, win10x64)${NC}"
read distro
echo -e "${YELLOW}Enter in a serial key now if you would like to be legit, otherwise you can skip this for now.${NC}"
read serial

print_status "${YELLOW}Mounting ISO if needed${NC}"
umount /mnt/$name
rm -rf /mnt/$name
chown $user:$user -R /mnt/$name
chown $user:$user -R /mnt/windows_ISOs/
mkdir  /mnt/$name
chown $user:$user /mnt/$name
mount -o loop,ro /mnt/windows_ISOs/* /mnt/$name &>> $logfile
error_check 'Mounted ISO'

echo -e "${YELLOW}Creating VM, some interaction may be required${NC}"
if [ -z "$serial" ]
then
su - $user -c "vmcloak init --$distro --vm-visible --ramsize $ram --cpus $cpu --iso-mount /mnt/$name $name" &>> $logfile
error_check 'Created VM'
else
su - $user -c "vmcloak init --$distro --vm-visible --ramsize $ram --cpus $cpu --serial-key $serial --iso-mount /mnt/$name $name" &>> $logfile
error_check 'Created VM'
fi

echo -e "${YELLOW}Installing programs on VM, some interaciton may be required${NC}"
su - $user -c "vmcloak install $name --vm-visible adobe9 flash wic python27 pillow dotnet java removetooltips wallpaper chrome" 
error_check 'Installed adobe9 wic pillow dotnet40 java7 removetooltips on VMs'

echo -e "${YELLOW}Starting VM and creating a running snapshot...Please wait.${NC}"  
su - $user -c "vmcloak snapshot $name $name" &>> $logfile
error_check 'Created snapshot'

echo
echo -e "${YELLOW}The VM is located under your user $user home folder under .vmcloak, you will need to register this with Virtualbox on your cuckoo account.${NC}"  

