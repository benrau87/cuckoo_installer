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

dir_check /mnt/windows_ISO &>> $logfile
dir_check /mnt/office_ISO &>> $logfile

interface="eth0"
user="cuckoo"
ip="192.168.56.100"
distro="win7x86"
name="win7x86"

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
echo -e "${YELLOW}What RDP port would you like to assign to this machine?${NC}"
read rdp
echo -e "${YELLOW}How much RAM would you like to allocate for this machine?${NC}"
read ram
echo -e "${YELLOW}How many CPU cores would you like to allocate for this machine?${NC}"
read cpu
echo -e "${YELLOW}What is the distro? (winxp, win7x86, win7x64, win81x86, win81x64, win10x86, win10x64)${NC}"
read distro
echo -e "${YELLOW}Enter in a Windows serial key now if you would like to be legit, otherwise you can skip this for now.${NC}"
read serial
echo -e "${YELLOW}Enter in a Office 2013 serial key now if you wish to install Office, otherwise you can skip this for now.${NC}"
read office_serial
echo -e "${YELLOW}What is the name for this machine?${NC}"
read name
echo
read -n 1 -s -p "Please place your Windows ISO in the folder under /mnt/windows_ISO and Office 2013 ISO in /mnt/office_ISO if you have one and press any key to continue"
echo
print_status "${YELLOW}Mounting ISO if needed${NC}"
mkdir  /mnt/$name &>> $logfile
mount -o loop,ro /mnt/windows_ISO/* /mnt/$name &>> $logfile
chown $user:$user /mnt/office_ISO/*
error_check 'Mounted ISOs'

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
sudo -i -u $user VBoxManage hostonlyif create
sudo -i -u $user VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1
vmcloak-iptables 192.168.56.0/24 $interface

echo -e "${YELLOW}Creating VM, hold on to your butts.${NC}"
if [ -z "$serial" ]
then
su - $user -c "vmcloak init --$distro --ramsize $ram --cpus $cpu  --iso-mount /mnt/$name $name" &>> $logfile
error_check 'Created VM'
else
su - $user -c "vmcloak init --$distro --serial-key $serial --ramsize $ram --cpus $cpu --iso-mount /mnt/$name $name" &>> $logfile
error_check 'Created VM'
fi
echo -e "${YELLOW}Installing programs on VM.${NC}"
if [ -z "$office_serial" ]
then
su - $user -c "vmcloak install $name adobe9 dotnet cuteftp flash wic python27 pillow java removetooltips wallpaper winrar chrome ie11" 
error_check 'Installed apps on VMs'
else
mv /mnt/office_ISO/* /mnt/office_ISO/office.iso
su - $user -c "vmcloak install $name office office.isopath=/mnt/office_ISO/office.iso office.serialkey=$office_serial activate=1"
su - $user -c "vmcloak install $name adobe9 dotnet cuteftp flash wic python27 pillow java removetooltips wallpaper winrar chrome ie11" 
error_check 'Installed apps on VMs'
fi

#echo -e "${YELLOW}Registering VM.${NC}"  
#su - $user -c "vmcloak clone $name $name " &>> $logfile
#su - $user -c "VBoxManage createvm --name $name --register" &>> $logfile
#su - $user -c "VBoxManage modifyvm --nic1 hostonly --memory $ram --cpus $cpu" &>> $logfile
#su - $user -c "VBoxManage storagectl $name --name "IDE Controller" --add ide" &>> $logfile
#su - $user -c "VBoxManage storageattach $name --storagectl 'IDE Controller' --port 0 --device 0 --type hdd --medium /home/$user/.vmcloak/image/$name.vdi" &>> $logfile

 
echo -e "${YELLOW}Starting VM and creating a running snapshot...Please wait.${NC}"  
su - $user -c "vmcloak snapshot $name $name" &>> $logfile
error_check 'Created snapshot'
echo

sudo -i -u $user VBoxManage modifyvm $name --vrdeport $rdp
 
