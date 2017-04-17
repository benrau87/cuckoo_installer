#!/bin/bash
cuckoo &
cp ~/conf/* ~/.cuckoo/conf/
cuckoo community
cuckoo migrate
