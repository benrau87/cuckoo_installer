#!/bin/bash
cuckoo &
sleep 20
cuckoo community
cp ~/conf/* ~/.cuckoo/conf
mkdir ~/.cuckoo/yara/IOCs/
cd ~/.cuckoo/yara/IOCs/
git clone https://github.com/Neo23x0/signature-base.git

