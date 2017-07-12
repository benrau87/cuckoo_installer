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
logfile=/var/log/nginx_install.log
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
echo
echo -e "${YELLOW}What is the name of the user account created for your cuckoo instance?${NC}"
read user
echo
echo -e "${YELLOW}What is the IP address of the machine that is hosting the cuckoo webpage, or enter 0.0.0.0 to host on all address on port 443?${NC}"
read ipaddr
echo
echo -e "${YELLOW}Please type in a user name for the website${NC}"
read webuser
##Install nginx
print_status "${YELLOW}Waiting for dpkg process to free up...${NC}"
print_status "${YELLOW}If this takes too long try running ${RED}sudo rm -f /var/lib/dpkg/lock${YELLOW} in another terminal window.${NC}"
while fuser /var/lib/dpkg/lock >/dev/null 2>&1; do
   sleep 1
done
print_status "${YELLOW}Installing Nginx...${NC}"
apt-get -qq install nginx apache2-utils -y &>> $logfile
usermod -a -G cuckoo $user &>> $logfile
error_check 'Nginx installed'
##Copy over service conf
cp nginx.service /lib/systemd/system/

##Create and secure keys
mkdir /etc/ssl/cuckoo/ &>> $logfile
cd /etc/ssl/cuckoo/ &>> $logfile
#openssl req -x509 -nodes -days 365 -newkey rsa:4096 -keyout cuckoo.key -out cuckoo.crt 
print_status "${YELLOW}Configuring and installing SSL keys...${NC}"
openssl req -subj '/CN=Cuckoo_Sandbox/'-x509 -nodes -days 3650 -newkey rsa:4096 -keyout cuckoo.key -out cuckoo.crt &>> $logfile
openssl dhparam -out dhparam.pem 4096 &>> $logfile
error_check 'SSL configured'
cd ..
mv cuckoo /etc/nginx &>> $logfile
mv /etc/nginx/cuckoo /etc/nginx/ssl &>> $logfile
chown -R root:www-data /etc/nginx/ssl &>> $logfile
chmod -R u=rX,g=rX,o= /etc/nginx/ssl &>> $logfile

##Remove default sites and create new cuckoo site
rm /etc/nginx/sites-enabled/default &>> $logfile

print_status "${YELLOW}Configuring Nginx webserver...${NC}"

sudo  cat >> /tmp/cuckoo <<EOF
server {
    listen $ipaddr:443 ssl http2;
    ssl_certificate /etc/nginx/ssl/cuckoo.crt;
    ssl_certificate_key /etc/nginx/ssl/cuckoo.key;
    ssl_dhparam /etc/nginx/ssl/dhparam.pem;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
    ssl_ecdh_curve secp384r1; # Requires nginx >= 1.1.0
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off; # Requires nginx >= 1.5.9
    # Uncomment this next line if you are using a signed, trusted cert
    #add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    root /usr/share/nginx/html;
    index index.html index.htm;
    client_max_body_size 101M;
    auth_basic "Login required";
    auth_basic_user_file /etc/nginx/htpasswd;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    location /storage/analysis {
       alias /etc/cuckoo-modified/storage/analyses/;
       autoindex on;
       autoindex_exact_size off;
       autoindex_localtime on;
    }

    location /static {
      alias /etc/cuckoo-modified/web/static/;
    }
}

server {
    listen $ipaddr:80 http2;
    return 301 https://\$server_name$request_uri;
}


#server {
#  listen 192.168.100.1:8080;

#   root /home/cuckoo/vmshared;

#     location / {
#           try_files \$uri \$uri/ =404;
#           autoindex on;
#           autoindex_exact_size off;
#           autoindex_localtime on;
#     }
#}
# Host the upstream legacy API 
server {
    listen $ipaddr:4343 ssl http2;
    ssl_certificate /etc/nginx/ssl/cuckoo.crt;
    ssl_certificate_key /etc/nginx/ssl/cuckoo.key;
    ssl_dhparam /etc/nginx/ssl/dhparam.pem;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_prefer_server_ciphers on;
    ssl_ciphers "EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH";
    ssl_ecdh_curve secp384r1; # Requires nginx >= 1.1.0
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off; # Requires nginx >= 1.5.9
   # Uncomment this next line if you are using a signed, trusted cert
    #add_header Strict-Transport-Security "max-age=63072000; includeSubdomains; preload";
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    root /usr/share/nginx/html;
    index index.html index.htm;
    client_max_body_size 101M;

    location / {
        proxy_pass http://127.0.0.1:8000
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        
        # Restrict access
       #allow IP_Address;
      #allow 192.168.1.0/24;
      #deny all;
    }
}
EOF

error_check 'Site configured'

mv /tmp/cuckoo /etc/nginx/sites-available/
ln -s /etc/nginx/sites-available/cuckoo /etc/nginx/sites-enabled/cuckoo

##Create web user and secure password storage
htpasswd -c /etc/nginx/htpasswd $webuser
chown root:www-data /etc/nginx/htpasswd
chmod u=rw,g=r,o= /etc/nginx/htpasswd

##Create and restart service
systemctl enable nginx.service
update-rc.d nginx defaults
service nginx restart






