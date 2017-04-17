#!/bin/bash
cp ~/conf/* ~/.cuckoo/conf/
cuckoo migrate
cuckoo community --all

