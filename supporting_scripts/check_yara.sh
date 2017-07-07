#!/bin/bash
mkdir /home/cuckoo/.cuckoo/yara/test/
mkdir /home/cuckoo/.cuckoo/yara/test/allrules
rules_path=/home/cuckoo/.cuckoo/yara/test/
cd $rules_path
git clone https://github.com/yara-rules/rules.git 
cp **/*.yar cd $rules_path/allrules
ls -d $rules_path/allrules/*.yar > index.txt

for x in index.txt
do
  vol.py -f /home/cuckoo/.cuckoo/storeage/analyses/12/memory.dmp
 else
  echo "Error in rule $x"
done




