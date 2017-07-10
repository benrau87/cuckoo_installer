#!/bin/bash
function dir_check()
{

if [ ! -d $1 ]; then
	echo "$1 does not exist. Creating.."
	mkdir -p $1
else
	echo "$1 already exists. (No problem, We'll use it anyhow)"
fi

}

dir_check /home/cuckoo/.cuckoo/yara/test/
dir_check /home/cuckoo/.cuckoo/yara/test/allrules
dir_check /home/cuckoo/Desktop/yararesults
dir_check /home/cuckoo/Desktop/yararesults/

rules_path=/home/cuckoo/.cuckoo/yara/test/
out_dir=/home/cuckoo/Desktop/yararesults/

cd $rules_path
git clone https://github.com/yara-rules/rules.git 

cp $rules_path/rules/**/*.yar $rules_path/allrules/
rm $rules_path/allrules/Android*
ls $rules_path/allrules/ > $rules_path/rules.txt

count=(ps aux | grep vol.py | wc -l)

for x in $(cat $rules_path/rules.txt)
do
  if [ $count -lt 5 ]; then # we are under the limit
     echo $x
     vol.py -f /home/cuckoo/.cuckoo/storage/analyses/12/memory.dmp --profile=Win7SP1x64 yarascan --yara-file=$rules_path/allrules/$x --output=text --output-file=$out_dir/$x.log &>/home/cuckoo/Desktop/error.txt  
  else
    wait
   fi
done

cat /home/cuckoo/Desktop/error.txt | grep Cannot | cut -d"/" -f9 | cut -d"("  -f1 > badrules.txt






