#!/bin/bash
gitdir=$PWD
wget https://github.com/finchy/pulledpork/archive/patch-3.zip
unzip patch-3.zip
cd pulledpork-patch-3
sudo cp pulledpork.pl /usr/local/bin/
chmod +x /usr/local/bin/pulledpork.pl
cp etc/*.conf /etc/snort/

/usr/local/bin/pulledpork.pl -V

cp $gitdir/pulledpork.conf /etc/snort/

/usr/local/bin/pulledpork.pl -V
/usr/local/bin/pulledpork.pl -c /etc/snort/pulledpork.conf -l
