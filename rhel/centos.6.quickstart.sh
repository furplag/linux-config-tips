#!/bin/sh
###
# centos.6.quickstart.sh
# https://github.com/furplag/linux-config-tips
# Copyright 2016 furplag
# Licensed under MIT (https://github.com/furplag/linux-config-tips/blob/master/LICENSE)

# More, easily create virtual machines for development disposable for my own.
# 1. Install Packages for Desktop.
# 2. Install package repositories.
# 3. Update packages.

datetime=`date +"%Y-%m-%d-%H_%M_%S"`
logDir=/tmp/centos-6.7.quickstart
[ -e $logDir/$datetime ] || mkdir -p $logDir/$datetime
logDir=$logDir/$datetime

# Install package groups
echo "Install package groups..."
yum groupinstall -y -q "Base" "Desktop" >/dev/null 2>&1
if [ ! $? ]; then
  echo "  yum groups \"Base\", \"Desktop\" install failed."
  exit 1
fi

echo "  package groups \"Base\", \"Desktop\" installed completely."

yum grouplist -v > $logDir/yum.groups.log 2>&1

# Install package repositories
echo -e "\nInstall package repositories..."
yum install -y -q \
 epel-release \
 http://www.city-fan.org/ftp/contrib/yum-repo/city-fan.org-release-1-13.rhel6.noarch.rpm \
 https://dl.iuscommunity.org/pub/ius/stable/Redhat/6/x86_64/ius-release-1.0-14.ius.el6.noarch.rpm >/dev/null 2>&1

if [ ! $? ]; then
  echo -e "  yum repositories \"city-fan.org\" \"epel\" \"ius\" install failed."
  exit 1
fi

sed -i -e 's/enabled=1/enabled=0/g' \
 /etc/yum.repos.d/city-fan.org.repo \
 /etc/yum.repos.d/epel* \
 /etc/yum.repos.d/ius*

yum repolist -v --disablerepo=* --enablerepo=city-fan.org,epel,ius > $logDir/yum.repos.log 2>&1

# Update packages
echo -e "\nUpdate packages..."
yum update -q -y --enablerepo=city-fan.org,epel,ius >/dev/null 2>&1 || \
 echo "  packages update failed."

# Install packages
echo -e "\nInstall packages..."
yum install -q -y file-roller firefox gedit git ntp open-vm-tools open-vm-tools-desktop wget --enablerepo=epel >/dev/null 2>&1 || \
 echo "  packages install failed."

echo -e "\nSet runlevel to \"Graphical\"..."
sed -i -e 's/id:[0-6]:/id:5:/' /etc/inittab

echo -e "\nComplete.\n  logFiles in [${logDir}]."

echo -e "\nNext step:\n  1. \"reboot\" yourself.\n  2. Desktop login.\n  3. General settings. e.g. \"Locale\", \"Timezone\", and Tools."
echo -e "\nAnd see https://github.com/furplag/linux-config-tops"
