#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit 1
fi

echo 1 | tee -a /proc/sys/net/ipv4/ip_forward 
sysctl -w net.ipv4.ip_forward=1 

sleep 5

cuckoo rooter &


