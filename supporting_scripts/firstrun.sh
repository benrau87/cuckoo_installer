#!/bin/bash
cuckoo &
sleep 20
cuckoo community
cp ~/conf/* ~/.cuckoo/conf


