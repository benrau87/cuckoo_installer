#!/bin/bash
cuckoo &
sleep 20
cuckoo community
cd ~/.cuckoo/yara/
git clone https://github.com/yara-rules/rules.git 

##Binary based rules
cp rules/CVE_Rules/*.yar ~/.cuckoo/yara/binaries/
cp rules/malware/*.yar ~/.cuckoo/yara/binaries/
cp rules/Crypto/*.yar ~/.cuckoo/yara/binaries/
cp rules/utils/*.yar ~/.cuckoo/yara/binaries/
cp rules/Malicious_Documents/*.yar ~/.cuckoo/yara/binaries/
cp rules/Packers/*.yar ~/.cuckoo/yara/binaries/
cp rules/emal/*.yar ~/.cuckoo/yara/binaries/
##URL based rules
cp rules/Webshells/*.yar ~/.cuckoo/yara/urls/

cp ~/conf/* ~/.cuckoo/conf
##Remove Android and none working rules for now
rm ~/.cuckoo/yara/binaries/Android* 
rm ~/.cuckoo/yara/binaries/vmdetect.yar  
rm ~/.cuckoo/yara/binaries/antidebug_antivm.yar  
rm ~/.cuckoo/yara/binaries/MALW_AdGholas.yar  
rm ~/.cuckoo/yara/binaries/APT_Shamoon*.yar  
rm ~/.cuckoo/yara/binaries/peid.yar  



