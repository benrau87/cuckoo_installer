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
git clone git://github.com/jbremer/vmcloak &>> $logfile
cd vmcloak &>> $logfile
pip install -r requirements.txt &>> $logfile
python setup.py develop &>> $logfile
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
#rand mac
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

echo
read -n 1 -s -p "Please place your Windows ISO in the folder under /mnt/windows_ISOs and press any key to continue"
echo

#echo -e "${YELLOW}What is the Windows disto?"
#read distro
echo -e "${YELLOW}What is the name for this machine?${NC}"
read name
echo -e "${YELLOW}How much RAM would you like to allocate for this machine?${NC}"
read ram
echo -e "${YELLOW}How many CPU cores would you like to allocate for this machine?${NC}"
read cpu
echo -e "${YELLOW}What is the distro? (winxp, win7x86, win7x64, win81x86, win81x64, win10x86, win10x64)${NC}"
read distro

print_status "${YELLOW}Mounting ISO if needed${NC}"
umount /mnt/$name
rm -rf /mnt/$name
mkdir  /mnt/$name
mount -o loop,ro /mnt/windows_ISOs/* /mnt/$name &>> $logfile
error_check 'Mounted ISO'

#--hwvirt
echo -e "${YELLOW}Creating VM, some interaction may be required${NC}"
vmcloak init --$distro --vm-visible --ramsize $ram --cpus $cpu --iso-mount /mnt/$name $name &>> $logfile
wait
vboxmanage modifyvm $name --macaddress $macadd
#--hwvirt
echo -e "${YELLOW}Creating VM, some interaction may be required${NC}"
vmcloak init --$distro --vm-visible --ramsize $ram --cpus $cpu --iso-mount /mnt/$name $name &>> $logfile
wait
error_check 'Created VM'

echo -e "${YELLOW}Modifying vm hardware IDs${NC}"
VBoxManage modifyvm $name --macaddress $macadd
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiBIOSFirmwareMajor	'0'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiBIOSFirmwareMinor	'0'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseDate	'07/02/2015'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseMajor	'4'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiBIOSReleaseMinor	'6'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVendor	'Hewlett-Packard'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiBIOSVersion	'F.49'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiBoardAssetTag	'Base Board Asset Tag'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiBoardBoardType	'10'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiBoardLocInChass	'Base Board Chassis Location'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiBoardProduct	'string:30FB'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiBoardSerial	'1CADF91932'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiBoardVendor	'Compal'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiBoardVersion	'01.9A'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiChassisAssetTag	'ems013463'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiChassisSerial	'string:A74E'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiChassisType	'10'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiChassisVendor	'Compal'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiChassisVersion	'N/A'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiOEMVBoxRev	'ABA'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiOEMVBoxVer	'ABS 70/71 79 7A 7B 7C'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiProcManufacturer	'AMD processor'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiProcVersion	'AMD Turion(tm) X2 Dual-Core Mobile RM-74'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiSystemFamily	'103C_5335KV'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiSystemProduct	'HP EliteBook Folio'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiSystemSKU	'HP Pavilion dv4 Notebook PC'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiSystemSerial	'5EFF05DA4E474DBBA373BB4E6F96BE9D'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiSystemUuid	'7059D844-1CF3-4BBF-B347-1EE644F1D969'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiSystemVendor	'Hewlett-Packard'
VBoxManage setextradata $name VBoxInternal/Devices/pcbios/0/Config/DmiSystemVersion	'string:1'

controller=`VBoxManage showvminfo $name--machinereadable | grep SATA`
if [[ -z "$controller" ]]; then
VBoxManage setextradata $name VBoxInternal/Devices/piix3ide/0/Config/PrimaryMaster/ModelNumber	'HITACHI HTD723216L9SA60'
VBoxManage setextradata $name VBoxInternal/Devices/piix3ide/0/Config/PrimaryMaster/SerialNumber	'379E6F6659874FC2B0AE'
VBoxManage setextradata $name VBoxInternal/Devices/piix3ide/0/Config/PrimaryMaster/FirmwareRevision	'FC2ZF50B'
else
VBoxManage setextradata $name VBoxInternal/Devices/ahci/0/Config/Port0/ModelNumber	'HITACHI HTD723216L9SA60'
VBoxManage setextradata $name VBoxInternal/Devices/ahci/0/Config/Port0/SerialNumber	'379E6F6659874FC2B0AE'
VBoxManage setextradata $name VBoxInternal/Devices/ahci/0/Config/Port0/FirmwareRevision	'FC2ZF50B'
fi
if [[ -z "$controller" ]]; then
VBoxManage setextradata $name VBoxInternal/Devices/piix3ide/0/Config/PrimarySlave/ATAPIVendorId	'HITACHI'
VBoxManage setextradata $name VBoxInternal/Devices/piix3ide/0/Config/PrimarySlave/ATAPIRevision	'B504'
VBoxManage setextradata $name VBoxInternal/Devices/piix3ide/0/Config/PrimarySlave/ATAPIProductId	'M2764AFI'
VBoxManage setextradata $name VBoxInternal/Devices/piix3ide/0/Config/PrimarySlave/ATAPISerialNumber	'2727F3EA983D458AAB19'
else
VBoxManage setextradata $name VBoxInternal/Devices/ahci/0/Config/Port1/ATAPIVendorId	'HITACHI'
VBoxManage setextradata $name VBoxInternal/Devices/ahci/0/Config/Port1/ATAPIRevision	'B504'
VBoxManage setextradata $name VBoxInternal/Devices/ahci/0/Config/Port1/ATAPIProductId	'M2764AFI'
VBoxManage setextradata $name VBoxInternal/Devices/ahci/0/Config/Port1/ATAPISerialNumber	'2727F3EA983D458AAB19'
fi
VBoxManage setextradata $name VBoxInternal/Devices/acpi/0/Config/AcpiOemId	'PTLTD'
VBoxManage setextradata $name VBoxInternal/Devices/acpi/0/Config/AcpiCreatorId	'MSFT'
VBoxManage setextradata $name VBoxInternal/Devices/acpi/0/Config/AcpiCreatorRev	'03000001'

#VBoxManage modifyvm $name--cpuidset 00000001 000306a9 04100800 7fbae3ff bfebfbff
VBoxManage setextradata $name VBoxInternal/CPUM/HostCPUID/80000002/eax  0x20444d41	
VBoxManage setextradata $name VBoxInternal/CPUM/HostCPUID/80000002/ebx  0x69727554	
VBoxManage setextradata $name VBoxInternal/CPUM/HostCPUID/80000002/ecx  0x74286e6f	
VBoxManage setextradata $name VBoxInternal/CPUM/HostCPUID/80000002/edx  0x5820296d	
VBoxManage setextradata $name VBoxInternal/CPUM/HostCPUID/80000003/eax  0x75442032	
VBoxManage setextradata $name VBoxInternal/CPUM/HostCPUID/80000003/ebx  0x432d6c61	
VBoxManage setextradata $name VBoxInternal/CPUM/HostCPUID/80000003/ecx  0x2065726f	
VBoxManage setextradata $name VBoxInternal/CPUM/HostCPUID/80000003/edx  0x69626f4d	
VBoxManage setextradata $name VBoxInternal/CPUM/HostCPUID/80000004/eax  0x5220656c	
VBoxManage setextradata $name VBoxInternal/CPUM/HostCPUID/80000004/ebx  0x34372d4d	
VBoxManage setextradata $name VBoxInternal/CPUM/HostCPUID/80000004/ecx  0x20202020	
VBoxManage setextradata $name VBoxInternal/CPUM/HostCPUID/80000004/edx  0x00202020
VBoxManage modifyvm $name--paravirtprovider legacy  

error_check 'Hardware modified'

echo -e "${YELLOW}Installing programs on VM, some interaciton may be required${NC}"
vmcloak install $name --vm-visible adobe9 flash wic python27 pillow dotnet java removetooltips wallpaper chrome &>> $logfile
error_check 'Installed adobe9 wic pillow dotnet40 java7 removetooltips on VMs'

echo
echo -e "${YELLOW}Starting VM and creating a running snapshot...Please wait.${NC}"  
vmcloak snapshot $name $name &>> $logfile
error_check 'Created snapshot'

echo
echo -e "${YELLOW}The VM is located under your current OR sudo user's home folder under .vmcloak, you will need to register this with Virtualbox on your cuckoo account.${NC}"  

