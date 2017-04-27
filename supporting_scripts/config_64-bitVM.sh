#!/bin/bash
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi
echo -e "${YELLOW}What VM would you like to create antivm scripts for?${NC}"
read name
python antivmdetect.py
mkdir $name/
cp DSDT-Intel* $name/DSDT_VMwareVirtualPlatform.bin
mv VMwareVirtualPlatform.sh $name/
mv VMwareVirtualPlatform.ps1 $name/
cd $name/
sed -i 's/"$1"/"$name/g' VMwareVirtualPlatform.sh
