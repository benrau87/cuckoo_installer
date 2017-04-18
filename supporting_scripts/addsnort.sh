#!/bin/bash
wget https://www.snort.org/downloads/snort/daq-2.0.6.tar.gz
tar -zxvf daq-2.0.6.tar.gz
cd daq*
./configure && make && make install
wget https://www.snort.org/downloads/snort/snort-2.9.9.0.tar.gz
tar -xvzf snort-2.9.8.3.tar.gz
cd snort*
./configure --enable-sourcefire && make && make install
ldconfig
ln -s /usr/local/bin/snort /usr/sbin/snort
groupadd snort
sudo useradd snort -r -s /sbin/nologin -c SNORT_IDS -g snort

mkdir -p /etc/snort/rules/iplists
mkdir -p /etc/snort/rules/iplists
mkdir /etc/snort/preproc_rules
mkdir /etc/snort/preproc_rules
mkdir /usr/local/lib/snort_dynamicrules
mkdir /usr/local/lib/snort_dynamicrules
mkdir /etc/snort/so_rules
mkdir /etc/snort/so_rules
mkdir -p /var/log/snort/archived_logs
mkdir -p /var/log/snort/archived_logs

touch /etc/snort/rules/iplists/black_list.rules
touch /etc/snort/rules/iplists/black_list.rules
touch /etc/snort/rules/iplists/white_list.rules
touch /etc/snort/rules/iplists/white_list.rules
touch /etc/snort/rules/local.rules
touch /etc/snort/rules/local.rules
touch /etc/snort/sid-msg.map
touch /etc/snort/sid-msg.map

chmod -R 5775 /etc/snort
chmod -R 5775 /var/log/snort
chmod -R 5775 /var/log/snort
chmod -R 5775 /usr/local/lib/snort_dynamicrules
chmod -R 5775 /usr/local/lib/snort_dynamicrules
chown -R snort:snort /etc/snort
chown -R snort:snort /etc/snort
chown -R snort:snort /var/log/snort
chown -R snort:snort /var/log/snort
chown -R snort:snort /usr/local/lib/snort_dynamicrules
chown -R snort:snort /usr/local/lib/snort_dynamicrules

cd snort_src/snort-*/etc/
cp *.conf* /etc/snort
cp *.map /etc/snort
cp *.dtd /etc/snort
cd ~/snort_src/snort-*/src/dynamic-preprocessors/build/usr/local/lib/snort_dynamicpreprocessor/
cp * /usr/local/lib/snort_dynamicpreprocessor/

sed -i "s/include \$RULE\_PATH/#include \$RULE\_PATH/" /etc/snort/snort.conf




snort -T -i vboxnet0 -c /etc/snort/snort.conf

