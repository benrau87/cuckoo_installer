# cuckoo_installer

**Tested on v2.0.6 with Ubuntu Server 16.04 AND 18.04**

Limited error and input checking, use at your own risk!

Chmod +x and run the setup.sh

Reboot and login to your cuckoo user

Create some VM templates using the vmcloak.sh script in your home directory, you will need a local copy of a Windows ISO.

After that you can import them to virtualbox with the import_ova.sh, VMs created this way will be hardened against
some anti-vm defenses and have many default applications installed. You will need to manually assign an IP address 
in the 192.168.56.0/24 range for each machine. The import_ova.sh script will boot the machines with RDP support which 
will allow you to connect and make any changes and install apps as needed before taking a snapshot.

When creating a Windows VM, you want to disable Windows updates and firewall. Use msconfig to turn off any update services that are not Microsoft related. If you installed Office, you should enable macros in the Trust Center. 

Machines added with the import_ova.sh script will also be added to your conf files for immediate use after running restart_cuckoo.sh

Start cuckoo with the restart_cuckoo.sh script on your cuckoo user in their home directory

Open your browser and point it at your host IP:8000

FIN

**Notes**

If using vmcloak to install VMs and you do not have VT-x, you can only use 1 core!
