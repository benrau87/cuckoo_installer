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
umount /mnt/windows_ISOs

if [ ! -d /usr/local/bin/vmcloak ]; then
print_status "${YELLOW}Installing vmcloak${NC}"
git clone git://github.com/jbremer/vmcloak &>> $logfile
cd vmcloak &>> $logfile
pip install -r requirements.txt
python setup.py develop &>> $logfile
error_check 'Installed vmcloak'
fi

echo
read -n 1 -s -p "Please place your Windows ISO in the folder under /mnt/windows_ISOs and press any key to continue"
echo

print_status "${YELLOW}Checking for host only interface${NC}"
ON=$(ifconfig -a | grep -cs 'vboxnet0')
if [[ $ON == 1 ]]
then
  echo "Host only interface is up"
else 
VBoxManage hostonlyif create
VBoxManage hostonlyif ipconfig vboxnet0 --ip 10.1.1.254
fi

print_status "${YELLOW}Mounting ISO if needed${NC}"
mount -o loop,ro  --source /mnt/windows_ISOs/*.iso --target /mnt/windows_ISOs/ &>> $logfile
error_check 'Mounted ISO'

#echo -e "${YELLOW}What is the Windows disto?"
#read distro
echo -e "${YELLOW}What is the IP  address you would like to assign this machine? (10.1.1.x)${NC}"
read ipaddress
echo -e "${YELLOW}What is the name for this machine?${NC}"
read name
echo -e "${YELLOW}How much RAM would you like to allocate for this machine?${NC}"
read ram
echo -e "${YELLOW}How many CPU cores would you like to allocate for this machine?${NC}"
read cpu
echo -e "${YELLOW}What is the key?${NC}"
read key
echo -e "${YELLOW}What is the distro? (winxp, win7x86, win7x64, win81x86, win81x64, win10x86, win10x64)${NC}"
read distro


echo -e "${YELLOW}###################################${NC}"
echo -e "${YELLOW}This process will take some time, you should get a sandwich, or watch the install if you'd really like...${NC}"
echo
sleep 5
#--hwvirt
vmcloak init --$distro --vm-visible --ramsize $ram --cpus $cpu --ip $ipaddress --serial-key $key --iso-mount /mnt/windows_ISOs/$name &>> $logfile
error_check 'Created VMs'
echo
read -p "Would you like to install Office 2007? This WILL require an ISO and key. Y/N" -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
dir_check /mnt/office2007 &>> $logfile
umount /mnt/office2007 &>> $logfile

echo
read -n 1 -s -p "Please place your Office 2007 ISO in the folder under /mnt/office2007/ and press any key to continue"
echo

mount -o loop,ro  --source /mnt/office2007/*.iso --target /mnt/office2007/ &>> $logfile
error_check 'ISO mounted'

echo -e "${YELLOW}What is the license key?${NC}"
read key
echo -e "${YELLOW}Installing Office 2007${NC}"
vmcloak install $name --vm-visible office2007 office2007.isopath=/mnt/office2007.iso office2007.serialkey=$key &>> $logfile
error_check 'Office 2007 installed'
fi
echo
echo -e "${YELLOW}Installing adobe9 wic pillow dotnet40 java7 removetooltips windows_cleanup chrome firefox_41 on the VM${NC}"
vmcloak install $name --vm-visible adobe9 wic pillow dotnet40 java7 removetooltips chrome &>> $logfile
error_check 'Installed adobe9 wic pillow dotnet40 java7 removetooltips on VMs'

echo
echo -e "${YELLOW}Starting VM and creating a running snapshot...Please wait.${NC}"  
vmcloak snapshot $name $name &>> $logfile
error_check 'Created snapshot'

echo
read -p "Would you like to register this machine with cuckoo? Y/N" -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]
then
python /etc/cuckoo-modified/utils/machine.py --add $name --ip $ipaddress --platform windows &>> $logfile
error_check 'VMs registered with cuckoo'
fi

echo -e "${YELLOW}Running some cleanup...Please wait.${NC}"  

umount /mnt/windows_ISOs &>> $logfile
umount /mnt/office2007 &>> $logfile


echo
echo -e "${YELLOW}The VM is located under your current OR sudo user's home folder under .vmcloak, you will need to register this with Virtualbox on your cuckoo account.${NC}"  

