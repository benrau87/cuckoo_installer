#!/bin/bash

CS_RULES=/opt/critical-stack/frameworks/intel/master-public.bro.dat
SURI_RULE_FILE=/etc/suricata/rules/cuckoo.rules
BL2=/opt/bl2ru2/bl2ru2/bl2ru2.py
rm $SURI_RULE_FILE
touch $SURI_RULE_FILE

awk '/ /{print $2 " " "Critical_Stack_Intel" " " $1}' $CS_RULES > /tmp/rules.list
$BL2 /tmp/rules.list -o $SURI_RULE_FILE

#echo 'alert http any any -> any any (msg:"FILE store all"; filestore; noalert; sid:15; rev:1;)' | tee -a $SURI_RULE_FILE
