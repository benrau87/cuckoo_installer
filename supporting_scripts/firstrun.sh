#!/bin/bash
if [ ! -d ~/.cuckoo ]; then
cuckoo 
sleep 20
cp ~/conf/* ~/.cuckoo/conf
cuckoo community
else
cuckoo community
fi
##Other yara rules
if [ ! -d ~/.cuckoo/yara/custom ]; then
mkdir ~/.cuckoo/yara/custom/
cd ~/.cuckoo/yara/custom/
git clone https://github.com/Neo23x0/signature-base.git
else
cd ~/.cuckoo/yara/custom/
rm -rf signature-base/
git clone https://github.com/Neo23x0/signature-base.git
fi
##More yara rules
if [ ! -d ~/.cuckoo/yara/custom/rules ]; then
cd ~/.cuckoo/yara/custom/
git clone https://github.com/Yara-Rules/rules.git
else
rm -rf ~/.cuckoo/yara/custom/rules
cd ~/.cuckoo/yara/custom/
git clone https://github.com/Yara-Rules/rules.git
fi
