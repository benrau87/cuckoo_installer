# cuckoo_installer

**Tested on v2.0.6 with Ubuntu Server 16.04**

Limited error and input checking, use at your own risk!

Chmod +x and run the setup.sh

Reboot and login to your cuckoo user

Create some VMs using the vmcloak.sh script in your home directory and add them to the virtualbox.conf file.

Start cuckoo with the start_cuckoo.sh script on your cuckoo user in their home directory

Open your browser and point it at your host IP:8000

FIN

**Notes**

When creating a Windows VM, you want to disable Windows updates and firewall. Use msconfig to turn off any update services that are not Microsoft related. If you installed Office, you should enable macros in the Trust Center. 

If using vmcloak to install VMs and you do not have VT-x, you can only use 1 core!
