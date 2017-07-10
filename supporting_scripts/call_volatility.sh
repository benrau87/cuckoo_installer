#!/bin/bash
x=$1
vol.py -f /home/cuckoo/.cuckoo/storage/analyses/12/memory.dmp --profile=Win7SP1x64 yarascan --yara-file=/home/cuckoo/.cuckoo/yara/test/allrules/$x --output=text --output-file=/home/cuckoo/Desktop/yararesults/$x.log &>/home/cuckoo/Desktop/error.txt
