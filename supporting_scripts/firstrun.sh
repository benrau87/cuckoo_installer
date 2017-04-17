#!/bin/bash

cuckoo migrate
cuckoo community --all
cp ~/conf/* ~/.cuckoo/conf/
