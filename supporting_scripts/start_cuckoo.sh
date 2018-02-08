#!/bin/bash
####################################################################################################################
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'
ON=$(ifconfig -a | grep -cs 'vboxnet0')
##Logging setup
logfile=/var/log/cuckoo_runlog.log
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

function up_check()
{

if [[ $(ps aux | grep -cs ${@}) -lt 1 ]]; then 
	systemctl start ${@}.service
else 
	print_good "All services on"
fi

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
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi
#sevice check
print_status "${YELLOW}Stopping existing Cuckoo services${NC}"
kill $(ps aux | grep '/usr/local/bin/cuckoo' | awk '{print $2}') &>> $logfile

print_status "${YELLOW}Starting essential services${NC}"
up_check mongodb elasticsearch mysql molochcapture molochviewer suricata tor uwsgi nginx
error_check 'All services running'
sleep 1
#start virtual network interface
print_status "${YELLOW}Checking for virtual interface${NC}"
sleep 1
t1=$(ifconfig -a | grep -o vboxnet0)
t2='vboxnet0'

if [ "$t1" = "$t2" ]; then
  VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 &>> $logfile
else
  VBoxManage hostonlyif create &>> $logfile
  VBoxManage hostonlyif ipconfig vboxnet0 --ip 192.168.56.1 &>> $logfile
fi
error_check 'Interface configured'

#start routing
print_status "${YELLOW}Configuring routing${NC}"
sleep 1
echo 1 | tee -a /proc/sys/net/ipv4/ip_forward &>> $logfile
sysctl -w net.ipv4.ip_forward=1 &>> $logfile
sleep 1
cuckoo rooter &
sleep 5
service uwsgi restart &>> $logfile
service tor restart &>> $logfile
error_check 'Routing configured'

print_status "${YELLOW}Launching Cuckoo...${NC}"
#start cuckoo
su - steve -c 'cuckoo' &
su - steve -c 'cuckoo process auto' &
error_check 'Cuckoo services launched'
