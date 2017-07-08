#!/bin/bash
apt-get -y install subversion build-essential bcc iasl xsltproc uuid-dev \
    zlib1g-dev libidl-dev libsdl1.2-dev libxcursor-dev libasound2-dev \
    libstdc++5 libpulse-dev libxml2-dev libxslt1-dev pyqt5-dev-tools \
    libqt5opengl5-dev qtbase5-dev-tools libcap-dev libxmu-dev \
    mesa-common-dev libglu1-mesa-dev linux-libc-dev libcurl4-openssl-dev \
    libpam0g-dev libxrandr-dev libxinerama-dev libqt5opengl5-dev makeself \
    libdevmapper-dev default-jdk texlive-latex-base texlive-latex-extra \
    texlive-latex-recommended texlive-fonts-extra texlive-fonts-recommended \
    lib32ncurses5 lib32z1 libc6-dev-i386 lib32gcc1 gcc-multilib \
    lib32stdc++6 g++-multilib genisoimage libvpx-dev qt5-default \
    qttools5-dev-tools libqt5x11extras5-dev libssl-dev python-all-dev \
    git-svn kbuild iasl libpng-dev libsdl-dev yasm qtdeclarative5-dev qml-module-qtquick-controls

ln -s libX11.so.6    /usr/lib32/libX11.so 
ln -s libXTrap.so.6  /usr/lib32/libXTrap.so 
ln -s libXt.so.6     /usr/lib32/libXt.so 
ln -s libXtst.so.6   /usr/lib32/libXtst.so
ln -s libXmu.so.6    /usr/lib32/libXmu.so
ln -s libXext.so.6   /usr/lib32/libXext.so
ln -s /lib/libgcc_s.so.1 /lib/libgcc_s.so

#qmake -qt=5 --version --with-qt-dir=/opt/qt53
#wget http://qt.mirror.constant.com/archive/qt/5.5/5.5.1/qt-opensource-linux-x64-5.5.1.run
#chmod 755 qt-opensource-linux-x64-5.5.1.run
#sudo ./qt-opensource-linux-x64-5.5.1.run

cd /home/cuckoo/sources/
svn co http://www.virtualbox.org/svn/vbox/trunk vbox
# Directories and filenames
SOURCESDIR=/home/cuckoo/sources/vbox                 # Dir where the vbox source code is
KMKTOOLSSUBDIR=kBuild/bin/linux.amd64                   # where we find the kmk tools e.g. kmk_md5sum
MD5SUMOUT=$SOURCESDIR/kmk_md5.out                   # log md5sum ops to this file
VBOXMANAGE=$SOURCESDIR/out/linux.amd64/release/bin/VXoxManage       # location and name of VBoxManage binary (after renamed)

# Suspicious strings to rename e.g. "VirtualBox" gets renamed to "XirtualXox" (no spaces, same length!)
VirtualBox=XirtualXox
virtualbox=xirtualxox
VIRTUALBOX=XIRTUALXOX
virtualBox=xirtualXox
vbox=vxox
Vbox=Vxox
VBox=VXox
VBOX=VXOX
Oracle=Xracle
oracle=xracle
innotek=xnnotek
InnoTek=XnnoTek
INNOTEK=XNNOTEK
PCI80EE=80EF
PCI80ee=80ef

# Logging some stuff of the installation to...
logfile="$(basename -s ".sh" $0).out"

# create special _echo function for output
exec 3>&1
_echo () {
    echo "$@" >&3
}

# all other stdout and stderr go to /dev/null
exec &> ./$logfile

me="$(basename $0)"
count=0
# Rename files and folders arg1=string in filename to search for, arg2=string to rename filename to
function rename_files_and_dirs {
    _echo "[*]Replacing string \"$1\" to \"$2\" in all filenames"
    a=0
    false
    while [ $? -ne 0 ]; do a=`expr $a + 1`;
        find . -name "*$1*" ! -name $me ! -name $logfile -exec bash -c "mv \"\$0\" \"\${0/$1/$2}\"" {} \;
    done;
}

function replace_strings {
    count=`expr $count + 1`
    _echo -n "$count/15 "
    _echo "[*]Replacing string \"$1\" with string \"$2\" in all files. Be patient this takes a while (~35sec on my box)..."
    find . -type f ! -name $me ! -name $logfile -exec sed -i "s/$1/$2/g" {} +
}


# ----------- Main ------------
_echo
_echo "[*] !!! ---- READ THIS BEFORE PROCEEDING ---- !!!"
_echo "[*]This scripts is patching the vbox souce code, compiles it and finally installs the VirtualBox application"
_echo "[*]Run this script as the user who is supposed to use the VirtualBox app later"
_echo "[*]Make sure you are in the vbox source code directory (same where the configure script is)"
_echo "[*]This script was tested on Ubuntu 16.04.1 LTS - Jan 2017"
_echo "[*]It comes as it is, it does not do too much error checking etc, if it doesn't work, fix it"
_echo
_echo "[*] !!! MAKE SURE YOU HAVE FIXED THE VARIABLES in the header of this script before proceeding (usrname, directories, etc)!!!"
_echo

if [ -d $SOURCESDIR ]; then
        cd $SOURCESDIR
else
    _echo "[ERROR]Did you changed the variables (see above)? SOURCEDIR does not exist. Aborting"
    exit 1
fi

if [ ! -f configure ] || [ ! -f Maintenance.kmk ]; then
    _echo "[ERROR]You are in the wrong directory. Aborting..."
    exit 1
fi



# Configuring and compiling the org. source first (this is neccessary to make the script work!)

    _echo "[*]Start configuring the source code."
    ./configure --disable-hardening >&3
    source $SOURCESDIR/kBuild/env.sh


    _echo "[*]Start compiling the org. source code. That takes a while. Get a coffee..."
    kmk >&3



    _echo "[*] Compiling the org. kernel modules"
    cd $SOURCESDIR/out/linux.amd64/release/bin/src/
    make >&3

    _echo "[*] Fixing access rights and cleaning up"
    cd $SOURCESDIR
    source ./env.sh
    kmk clean
    sudo chown -R $USER:$(id -gn) *
    sudo chown -R $USER:$(id -gn) .*


    _echo "[*]Logging to $logfile"
    _echo "[*]Renaming files"

    # Rename files and folders
    rename_files_and_dirs VirtualBox $VirtualBox
    rename_files_and_dirs virtualbox $virtualbox
    rename_files_and_dirs vbox $vbox
    rename_files_and_dirs VBox $VBox
    rename_files_and_dirs Oracle $Oracle
    rename_files_and_dirs oracle $oracle

    _echo "[*]Starting string replacment. All 15 rounds are taking approx. 10min on my box, so go and get a coffee"
    replace_strings VirtualBox $VirtualBox
    replace_strings virtualbox $virtualbox
    replace_strings VIRTUALBOX $VIRTUALBOX
    replace_strings virtualBox $virtualBox
    replace_strings vbox $vbox
    replace_strings Vbox $Vbox
    replace_strings VBox $VBox
    replace_strings VBOX $VBOX
    replace_strings Oracle $Oracle
    replace_strings oracle $oracle
    replace_strings innotek $innotek
    replace_strings InnoTek $InnoTek
    replace_strings INNOTEK $INNOTEK
    replace_strings 80EE $PCI80EE
    replace_strings 80ee $PCI80ee

    _echo "[*]Replacing BIOS date"
    sed -i 's/06\/23\/99/07\/24\/13/g' $SOURCESDIR/src/VXox/Devices/PC/BIOS/orgs.asm

    _echo "[*]Compiling source code"
    ./configure --disable-hardening >&3
    source $SOURCESDIR/env.sh
    replace_strings QVXoxLayout QVBoxLayout

    _echo "[*]Replacing kmk_md5 tools with our version to fix MAKE's BIOS check"
    if [ -e "$SOURCESDIR/$KMKTOOLSSUBDIR/kmk_md5sum" ]; then
        mv $SOURCESDIR/$KMKTOOLSSUBDIR/kmk_md5sum $SOURCESDIR/$KMKTOOLSSUBDIR/kmk_md5sum.bak
        cat > $SOURCESDIR/$KMKTOOLSSUBDIR/kmk_md5sum <<- EOF
        #!/bin/bash
        echo \$2 >>$MD5SUMOUT
        echo \$2
        echo
EOF
        chmod +x $SOURCESDIR/$KMKTOOLSSUBDIR/kmk_md5sum
    else
        _echo "[ERROR] File \"$SOURCESDIR/$KMKTOOLSSUBDIR/kmk_md5sum\" not found"
        exit 1
    fi

    _echo "[*]Start compiling source code. That takes a while. Get a coffee..."

    _echo "[*]Patching BIOS date in autom. generated files"
    _echo "[*]File: out/linux.amd64/release/obj/PcBiosBin/PcBiosBin286.c"
    sed -i 's/06\.23\.99/07\.24\.13/g' $SOURCESDIR/out/linux.amd64/release/obj/PcBiosBin/PcBiosBin286.c
    sed -i 's/0x30\, 0x36\, 0x2f\, 0x32\, 0x33\, 0x2f\, 0x39\, 0x39/0x30\, 0x37\, 0x2f\, 0x32\, 0x34\, 0x2f\, 0x31\, 0x32/g' out/linux.amd64/release/obj/PcBiosBin/PcBiosBin286.c >&3

    _echo "[*]File: out/linux.amd64/release/obj/PcBiosBin/PcBiosBin386.c"
    sed -i 's/06\.23\.99/07\.24\.13/g' $SOURCESDIR/out/linux.amd64/release/obj/PcBiosBin/PcBiosBin386.c
    sed -i 's/0x30\, 0x36\, 0x2f\, 0x32\, 0x33\, 0x2f\, 0x39\, 0x39/0x30\, 0x37\, 0x2f\, 0x32\, 0x34\, 0x2f\, 0x31\, 0x32/g' out/linux.amd64/release/obj/PcBiosBin/PcBiosBin386.c >&3

    _echo "[*]File: out/linux.amd64/release/obj/PcBiosBin/PcBiosBin8086.c"
    sed -i 's/06\.23\.99/07\.24\.13/g' $SOURCESDIR/out/linux.amd64/release/obj/PcBiosBin/PcBiosBin8086.c
    sed -i 's/0x30\, 0x36\, 0x2f\, 0x32\, 0x33\, 0x2f\, 0x39\, 0x39/0x30\, 0x37\, 0x2f\, 0x32\, 0x34\, 0x2f\, 0x31\, 0x32/g' out/linux.amd64/release/obj/PcBiosBin/PcBiosBin8086.c >&3

    _echo "[*] Compiling BIOS files again."
    kmk >&3


# compile kernel modules
    _echo "[*] Compiling kernel modules"
    cd $SOURCESDIR/out/linux.amd64/release/bin/src/
    make


    _echo "[*] Installing kernel modules"
    sudo make install


_echo "[*]Compiling source code is done."


# -------- Installing Virtual Box ---------

cd $SOURCESDIR/out/linux.amd64/release/bin

# Take care of kernel modules
if [ "$(lsmod | grep vxox)" ]; then
    _echo "[*] vxox kernel modules already loaded. Unloading them..."
    sudo rmmod vxoxpci
    sudo rmmod vxoxnetflt
    sudo rmmod vxoxnetadp
    sudo rmmod vxoxdrv
fi

_echo "[*] Loading vxox kernel modules"
sudo modprobe vxoxdrv
sudo modprobe vxoxnetflt
sudo modprobe vxoxnetadp
sudo modprobe vxoxpci

_echo "[*] Following modules loaded:"
lsmod | grep vxox

    _echo "[*] Adding modules to /etc/modules"
    echo 'vxoxdrv'    | sudo tee --append /etc/modules > /dev/null
    echo 'vxoxpci'    | sudo tee --append /etc/modules > /dev/null
    echo 'vxoxnetadp' | sudo tee --append /etc/modules > /dev/null
    echo 'vxoxnetflt' | sudo tee --append /etc/modules > /dev/null


    if [ -e "/usr/local/virtualbox" ]; then
        _echo "Deleting old /usr/local/virtualbox folder"
        sudo rm -rf /usr/local/virtualbox
    fi
    
    sudo mkdir /usr/local/virtualbox
    _echo "Copying binaries to /usr/local/virtualbox"
    sudo cp -prf $SOURCESDIR/out/linux.amd64/release/bin/*    /usr/local/virtualbox/
    _echo "Copying shared libraries to /usr/lib/"
    sudo cp -prf $SOURCESDIR/out/linux.amd64/release/bin/*.so /usr/lib/
    _echo "Creating some symlinks to e.g. XirtualXox to VirtualBox"
    if [ ! -e "/usr/local/bin/VirtualBox" ]; then sudo ln -s /usr/local/virtualbox/XirtualXox  /usr/local/bin/VirtualBox; fi
    if [ ! -e "/usr/local/bin/VBoxSVC"    ]; then sudo ln -s /usr/local/virtualbox/VXoxSVC     /usr/local/bin/VBoxSVC;    fi
    if [ ! -e "/usr/local/bin/VBoxManage" ]; then sudo ln -s /usr/local/virtualbox/VXoxManage  /usr/local/bin/VBoxManage; fi



    if [ -e "/etc/udev/rules.d/40-permissions.rules" ]; then
        sudo cp /etc/udev/rules.d/40-permissions.rules /etc/udev/rules.d/40-permissions.rules.vboxinstaller.bak
        else 
        touch /etc/udev/rules.d/40-permissions.rules
    fi

    _echo "[*]Adding devices in /etc/udev/rules.d/40-permissions.rules"
    echo 'KERNEL=="vxoxdrv",                        GROUP="vboxusers", MODE="0660"' \
        | sudo tee --append /etc/udev/rules.d/40-permissions.rules > /dev/null
    echo 'KERNEL=="vxoxdrv",                        GROUP="vboxusers", MODE="0660"' \
        | sudo tee --append /etc/udev/rules.d/40-permissions.rules > /dev/null
    echo 'KERNEL=="vxoxdrvu",                       GROUP="vboxusers", MODE="0660"' \
        | sudo tee --append /etc/udev/rules.d/40-permissions.rules > /dev/null


