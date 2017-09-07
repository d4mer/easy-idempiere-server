#!/bin/bash -x
#
# Author : Ed Arellano
#
# Notes :
#   This script is a simple "helper" to configure your fresh linux server for Idempiere
#   There is no silver bullet. Don't expect the perfect setup, review comments
#   and adapt the parameters to your needs and application usage.
#
#   Use this script at your OWN risk. There is no guarantee whatsoever.
#
# License :
#   This work is licenced under the CC-GNU LGPL version 2.1 or later.
#   To view a copy of this licence, visit http://creativecommons.org/licenses/LGPL/2.1/
#   or send a letter to :
#
#           Creative Commons
#           171 Second Street, Suite 300
#           San Francisco, California 94105, USA
#

#######################################################################################
# Get the various info to write the interfaces file
#######################################################################################

getinfo()
{
  read -p "Enter the interface name of your network adapter:          (looks like eth01)   " iface
  read -p "Enter the IP of your router:          (looks like 192.168.1.1)   " routerip
  read -p "Enter the netmask for your network:   (looks like 255.255.255.0) " netmask
  read -p "Enter the ip address for your server: (looks like 192.168.1.22)  " staticip
  read -p "Enter the dns servers you would like to use: (Maybe 8.8.8.8)  " dns
  
}

#######################################################################################
# Determine if this a VBox machine
#######################################################################################

#getvminfo()
#{
#	read -p "Is this a Virtual Machine? " -n vmdata
#}		

#######################################################################################
#Install VBox addons
#######################################################################################

vboxaddons()
{
		sudo mount /dev/cdrom /media/cdrom
	
	sudo apt-get install -y dkms build-essential linux-headers-generic linux-headers-$(uname -r)
	
sudo /media/cdrom/VBoxLinuxAdditions.run
	break
}

#######################################################################################
# Write the interfaces file
#######################################################################################

writeinterfacefile() {
cat << EOF >> $1 

# Your static network configuration  
iface $iface inet static
address $staticip
netmask $netmask
gateway $routerip 
dns-nameserver $dns
EOF
#don't use any space before of after 'EOF' in the previous line

  echo ""
  echo "The informaton was saved in '$1' file."
  echo ""
break
}

#######################################################################################
#Determine if the interfaces file exists
#######################################################################################

writeInterfacesHeader(){

cat << EOF >> $3
    # This file describes the network interfaces available on your system
    # and how to activate them. For more information, see interfaces(5).
    # The loopback network interface
    auto lo
    iface lo inet loopback
    # The primary network interface
    auto $iface
    iface $iface inet dhcp
EOF
    echo ""
    echo "The informaton was saved in '$3' file."
    echo ""
break
}

file="/etc/network/interfaces"
if [ ! -f $file ]; then
  echo ""
  echo "The file '$file' doesn't exist!"
  echo ""
  echo "Let's create it"

  touch /etc/network/interfaces

  writeInterfacesHeader
  #exit 1
fi

#######################################################################################
#Let's get the available ethernet adapters on this system
#######################################################################################

getifaceinfo()
{

	ifconfig | cut -c 1-8 | sort | uniq -u | grep -v lo | awk -F':' '{ print $1}'
	
}

#######################################################################################
#Clear the terminal and ask for the needed info
#######################################################################################

clear
echo "Let's set up a static ip address for your site"
echo ""
echo "Here are the available ethernet adapters on your system. You'll need to choose one in the next step."
echo ""
echo "$(getifaceinfo)"
echo ""
#echo "$(getvminfo)"
echo ""

#######################################################################################
#Make sure the settings are correct
#######################################################################################

getinfo
echo ""
echo "So your settings are:"
echo "Inet adapter name is: $iface"
echo "Address of your Router is:   $routerip"
echo "The Mask for the Network is: $netmask"
echo "Your decided Server IP is:   $staticip"
echo "Your DNS is: $dns"
echo ""

while true; do
  read -p "Is this information correct? [y/n]: " yn 
  case $yn in
    [Yy]* ) writeinterfacefile $file;;
    [Nn]* ) getinfo;;
        * ) echo "Please enter y or n!";;
  esac
done

#######################################################################################
#Lets restart the interfaces
#######################################################################################

ifdown $iface && ifup $iface

#######################################################################################
#Time to start updating the system
#######################################################################################

sudo apt-get update && sudo apt-get upgrade --force-yes

#######################################################################################	
#Loop to determine if it is a virtual machine
#######################################################################################

while true; do
  read -p "Is this a virtual machine? [y/n]: " yn 
  case $yn in
    [Yy]* ) vboxaddons;;
    [Nn]* ) break;;
        * ) echo "Please enter y or n.";;
  esac
done


#######################################################################################
# Install Webmin
#######################################################################################

fileSource="/etc/apt/sources.list"
installWebmin()
{
cat << EOF >> $1
# Webmin sources
deb http://download.webmin.com/download/repository sarge contrib
deb http://webmin.mirror.somersettechsolutions.co.uk/repository sarge contrib
EOF
#don't use any space before of after 'EOF' in the previous line
echo ""
echo "The informaton was saved in '$1' file."
echo ""

    wget -q http://www.webmin.com/jcameron-key.asc -O- | sudo apt-key add -
    sudo apt-get install webmin --force-yes
break
}


while true; do
  read -p "Would you like to install Webmin? [y/n]: " yn
  case $yn in
    [Yy]* ) installWebmin $fileSource;;
    [Nn]* ) break;;
        * ) echo "Please enter y or n.";;
  esac
done

while true; do
  read -p "Would you like to install security measures? [y/n]: " yn
  case $yn in
    [Yy]* ) sudo apt install tiger logwatch fail2ban --force-y;;
    [Nn]* ) break;;
        * ) echo "Please enter y or n.";;
  esac
done
#######################################################################################
#Install the necessary software
#######################################################################################
sudo apt-get install openssh-client openssh-server landscape-common nmap p7zip-full libdate-manip-perl --force-yes postgresql postgresql-contrib
