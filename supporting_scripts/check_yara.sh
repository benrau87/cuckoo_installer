#!/bin/bash
function dir_check()
{

if [ ! -d $1 ]; then
	print_notification "$1 does not exist. Creating.."
	mkdir -p $1
else
	print_notification "$1 already exists. (No problem, We'll use it anyhow)"
fi

}

dir_check /home/cuckoo/.cuckoo/yara/test/
dir_check /home/cuckoo/.cuckoo/yara/test/allrules
rules_path=/home/cuckoo/.cuckoo/yara/test/
cd $rules_path
git clone https://github.com/yara-rules/rules.git 

for y in $(ls -d $rules_path/rules/*/)
do
  ls -d $y/*.yar | tee -a $rules_path/index.txt
done

for x in $rules_path/index.txt
do
  vol.py -f /home/cuckoo/.cuckoo/storeage/analyses/12/memory.dmp --profile=Win7SP1x64 yarascan --yara-file=$x
done




