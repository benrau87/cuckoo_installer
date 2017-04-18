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
mkdir /etc/snort
mkdir /etc/snort/preproc_rules
mkdir /etc/snort/rules
mkdir /var/log/snort
mkdir /usr/local/lib/snort_dynamicrules
touch /etc/snort/rules/white_list.rules
touch /etc/snort/rules/black_list.rules
touch /etc/snort/rules/local.rules
chmod -R 5775 /etc/snort/
chmod -R 5775 /var/log/snort/
chmod -R 5775 /usr/local/lib/snort
chmod -R 5775 /usr/local/lib/snort_dynamicrules/
cp -avr *.conf *.map *.dtd /etc/snort/
cp -avr src/dynamic-preprocessors/build/usr/local/lib/snort_dynamicpreprocessor/*  /usr/local/lib/snort_dynamicpreprocessor/
sed -i "s/include \$RULE\_PATH/#include \$RULE\_PATH/" /etc/snort/snort.conf

snort -T -i vboxnet0 -c /etc/snort/snort.conf

