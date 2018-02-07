##Webserver
print_status "${YELLOW}Configuring webserver${NC}"
sudo adduser www-data $name  &>> $logfile
sudo -i -u $name cuckoo web --uwsgi > /etc/uwsgi/apps-available/cuckoo-web.ini  &>> $logfile
ln -s /etc/uwsgi/apps-available/cuckoo-web.ini /etc/uwsgi/apps-enabled/  &>> $logfile
sudo -i -u $name cuckoo web --nginx > /etc/nginx/sites-available/cuckoo-web  &>> $logfile
ln -s /etc/nginx/sites-available/cuckoo-web /etc/nginx/sites-enabled/ &>> $logfile
sudo -i -u $name cuckoo api --uwsgi > /etc/uwsgi/apps-available/cuckoo-api.ini  &>> $logfile
ln -s /etc/uwsgi/apps-available/cuckoo-api.ini /etc/uwsgi/apps-enabled/ &>> $logfile
sudo -i -u $name cuckoo api --nginx > /etc/nginx/sites-available/cuckoo-api &>> $logfile
ln -s /etc/nginx/sites-available/cuckoo-api /etc/nginx/sites-enabled/ &>> $logfile
