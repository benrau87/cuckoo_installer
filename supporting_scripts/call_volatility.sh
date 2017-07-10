#!/bin/bash
x=$1
vol.py -f /home/cuckoo/.cuckoo/storage/analyses/12/memory.dmp \
     --profile=Win7SP1x64 yarascan \
     --yara-file=$rules_path/allrules/$x \
     --output=text \
     --output-file=$out_dir/$x.log \
     &>/home/$name/Desktop/error.txt
