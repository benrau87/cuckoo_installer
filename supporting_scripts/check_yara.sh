#!/bin/bash
mkdir /home/cuckoo/.cuckoo/yara/test/
mkdir /home/cuckoo/.cuckoo/yara/test/allrules
rules_path=/home/cuckoo/.cuckoo/yara/test/
cd $rules_path
git clone https://github.com/yara-rules/rules.git 

for y in $(ls -d $rules_path/rules/*/)
do
  ls -d $y/*.yar | tee -a $rules_path/index.txt

for x in $rules_path/index.txt
do
  vol.py -f /home/cuckoo/.cuckoo/storeage/analyses/12/memory.dmp --profile=Win7SP1x64 yarascan --yara-file=$x
 else
  echo "Error in rule $x"
done




