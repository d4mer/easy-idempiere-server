#!/bin/bash
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


# Get the various info to write the interfaces file
getinfo()
{
  read -p "Enter the interface name of your network adapter:          (looks like eth01)   " iface
  read -p "Enter the IP of your router:          (looks like 192.168.1.1)   " routerip
  read -p "Enter the netmask for your network:   (looks like 255.255.255.0) " netmask
  read -p "Enter the ip address for your server: (looks like 192.168.1.22)  " staticip
  read -p "Enter the dns servers you would like to use: (Maybe 8.8.8.8)  " dns
  
}

# Write the interfaces file
writeinterfacefile()
{ 
cat << EOF >> $1 
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).
# The loopback network interface
auto lo
iface lo inet loopback
# The primary network interface
auto eth0
iface eth0 inet dhcp

# Your static network configuration  
iface $iface inet static
address $staticip
netmask $netmask
gateway $routerip 
EOF
#don't use any space before of after 'EOF' in the previous line

  echo ""
  echo "The informaton was saved in '$1' file."
  echo ""
  exit 0
}

file="/Users/imac/test/interfaces"
if [ ! -f $file ]; then
  echo ""
  echo "The file '$file' doesn't exist!"
  echo ""
  exit 1
fi

#Let's get the available ethernet adapters on this system
getifaceinfo()
{

	ifconfig | cut -c 1-8 | sort | uniq -u | grep -v lo | awk -F':' '{ print $1}'
	
}

clear
echo "Let's set up a static ip address for your site"
echo ""
echo "Here are the available ethernet adapters on your system. You'll need to choose one in the next step."
echo "$(getifaceinfo)"
echo ""

getinfo
echo ""
echo "So your settings are:"
echo "Inet adapter name is: $iface"
echo "Address of your Router is:   $routerip"
echo "The Mask for the Network is: $netmask"
echo "Your decided Server IP is:   $staticip"
echo ""

while true; do
  read -p "Is this information correct? [y/n]: " yn 
  case $yn in
    [Yy]* ) writeinterfacefile $file;;
    [Nn]* ) getinfo;;
        * ) echo "Please enter y or n!";;
  esac
done

ifdown $iface && ifup $iface
