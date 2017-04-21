#!/bin/bash
cuckoo &
sleep 20
cuckoo community
cp ~/.mitmproxy/mitmproxy-ca-cert.p12 ~/.cuckoo/analyzer/windows/bin/cert.p12
cp ~/conf/* ~/.cuckoo/conf/

cd ~/.cuckoo/yara/
git clone https://github.com/yara-rules/rules.git &>> $logfile
cp rules/**/*.yar ~/.cuckoo/yara/binaries/ &>> $logfile
##Remove Android and none working rules for now
rm ~/.cuckoo/yara/binaries/Android* 
rm ~/.cuckoo/yara/binaries/vmdetect.yar  &>> $logfile
rm ~/.cuckoo/yara/binaries/antidebug_antivm.yar  &>> $logfile
rm ~/.cuckoo/yara/binaries/MALW_AdGholas.yar  &>> $logfile
rm ~/.cuckoo/yara/binaries/APT_Shamoon*.yar  &>> $logfile



