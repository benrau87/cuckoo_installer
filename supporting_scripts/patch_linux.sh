#!/bin/bash
apt-get install uml-utilities bridge-utils
apt-get install systemtap gcc patch linux-headers-$(uname -r)
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C8CAB6595FDFF622

codename=$(lsb_release -cs)

tee /etc/apt/sources.list.d/ddebs.list << EOF
  deb http://ddebs.ubuntu.com/ ${codename}          main restricted universe multiverse
  #deb http://ddebs.ubuntu.com/ ${codename}-security main restricted universe multiverse
  deb http://ddebs.ubuntu.com/ ${codename}-updates  main restricted universe multiverse
  deb http://ddebs.ubuntu.com/ ${codename}-proposed main restricted universe multiverse
EOF

apt-get update

apt-get install linux-image-$(uname -r)-dbgsym

wget https://raw.githubusercontent.com/cuckoosandbox/cuckoo/master/stuff/systemtap/expand_execve_envp.patch
wget https://raw.githubusercontent.com/cuckoosandbox/cuckoo/master/stuff/systemtap/escape_delimiters.patch
patch /usr/share/systemtap/tapset/linux/sysc_execve.stp < expand_execve_envp.patch
patch /usr/share/systemtap/tapset/uconversions.stp < escape_delimiters.patch

wget https://raw.githubusercontent.com/cuckoosandbox/cuckoo/master/stuff/systemtap/strace.stp
stap -p4 -r $(uname -r) strace.stp -m stap_ -v

staprun -v ./stap_.ko

mkdir /root/.cuckoo
mv stap_.ko /root/.cuckoo/

ufw disable

timedatectl set-ntp off

apt-get purge update-notifier update-manager update-manager-core ubuntu-release-upgrader-core -y
apt-get purge whoopsie ntpdate cups-daemon avahi-autoipd avahi-daemon avahi-utils -y
apt-get purge account-plugin-salut libnss-mdns telepathy-salut -y
