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
  ls -d $y/*.yar | tee $rules_path/index.txt
done

#for x in $(cat $rules_path/index.txt)
#do
#  vol.py -f /home/cuckoo/.cuckoo/storage/analyses/12/memory.dmp --profile=Win7SP1x64 yarascan --yara-file=$x
#done

#mkfifo /home/cuckoo/Desktop/results.txt # creating named pipe
out_file=/home/cuckoo/Desktop/results.txt
counter=0

for x in $(cat $rules_path/index.txt)
do
  if [ $counter -lt 5 ]; then # we are under the limit
    vol.py -f /home/cuckoo/.cuckoo/storage/analyses/12/memory.dmp --profile=Win7SP1x64 yarascan --yara-file=$x | tee -a $out_file &
    let $[counter++];
  else
    read x < $out_file # waiting for a process to finish
    vol.py -f /home/cuckoo/.cuckoo/storage/analyses/12/memory.dmp --profile=Win7SP1x64 yarascan --yara-file=$x | tee -a $out_file &
   fi
done
cat $out_file > /dev/null # let all the background processes end

#rm $out_file # remove fifo
