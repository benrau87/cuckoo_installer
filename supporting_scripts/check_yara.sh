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
dir_check /home/cuckoo/Desktop/yararesults
rules_path=/home/cuckoo/.cuckoo/yara/test/
cd $rules_path
#git clone https://github.com/yara-rules/rules.git 

for y in $(ls -d $rules_path/rules/*/)
do
  ls -d $y/*.yar | tee $rules_path/index.txt
done
cat $rules_path/index.txt | cut -d"/" -f11,12 > rules.txt
#for x in $(cat $rules_path/index.txt)
#do
#  vol.py -f /home/cuckoo/.cuckoo/storage/analyses/12/memory.dmp --profile=Win7SP1x64 yarascan --yara-file=$x
#done


#mkfifo /home/cuckoo/Desktop/results.txt # creating named pipe
#pipe=/home/cuckoo/Desktop/results.txt
out_dir=/home/cuckoo/Desktop/yararesults/
#counter=0


for x in $(cat $rules_path/rules.txt)
do
     while [`jobs | wc -l` -ge 20]
     do
     sleep 1
     done
     touch $out_dir/$x.log
     vol.py -f /home/cuckoo/.cuckoo/storage/analyses/12/memory.dmp --profile=Win7SP1x64 yarascan --yara-file=$rules_path/allrules/$x | tee -a $out_dir/$x.log &
done











#for x in $(cat $rules_path/index.txt)
#do
#  if [ $counter -lt 5 ]; then # we are under the limit
#    vol.py -f /home/cuckoo/.cuckoo/storage/analyses/12/memory.dmp --profile=Win7SP1x64 yarascan --yara-file=$x | tee -a $out_dir/$x.log > $pipe &
#    let $[counter++];
#  else
#    read x < $out_file # waiting for a process to finish
#    vol.py -f /home/cuckoo/.cuckoo/storage/analyses/12/memory.dmp --profile=Win7SP1x64 yarascan --yara-file=$x | tee -a $out_dir/$x.log > $pipe &
#   fi
#done
#cat $pipe > /dev/null # let all the background processes end

#rm $pipe # remove fifo
