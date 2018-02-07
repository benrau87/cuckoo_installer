#!/bin/bash
if [ ! -d ~/.cuckoo ]; then
cuckoo 
wait
cp ~/conf/* ~/.cuckoo/conf
cuckoo community
cuckoo migrate
else
cuckoo community
fi

