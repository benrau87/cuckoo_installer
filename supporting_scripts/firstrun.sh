#!/bin/bash
if [ ! -d ~/.cuckoo ]; then
cuckoo &
sleep 20
cp ~/conf/* ~/.cuckoo/conf
else
cuckoo community
if [ ! -d ~/.cuckoo/yara/IOCs ]; then
mkdir ~/.cuckoo/yara/IOCs/
cd ~/.cuckoo/yara/IOCs/
git clone https://github.com/Neo23x0/signature-base.git
else
cd ~/.cuckoo/yara/IOCs/
rm -rf signature-base/
git clone https://github.com/Neo23x0/signature-base.git

