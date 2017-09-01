# CentOS 7
###### CentOS Linux release 7.3.1611 (Core)
## Install "Minimal Desktop" in CentOS 7
##### Install required packages for Using Desktop.
```bash
yum groupinstall -y "X Window System" && \
 yum install -y control-center \
 gnome-classic-session \
 gnome-terminal \
 nautilus-open-terminal
```
##### Change runlevel to "graphical".
```bash
systemctl set-default graphical.target

# And also, if you building Virtual Machine.
yum install -y open-vm-tools open-vm-tools-desktop
```
###### And optional,

```bash
# Note: Recommend: to use "Settings" in Desktop.

# change default Locale.
localectl set-locale LANG=[language_Country.Charset]

# change default Timezone.
timedatectl set-timezone [zoneinfo]
```
then "`shutdown -r now`".

---
###### Notes: only for my own
```bash
# Install external repositories
yum install -y epel-release \
 http://www.city-fan.org/ftp/contrib/yum-repo/city-fan.org-release-1-13.rhel7.noarch.rpm \
 https://dl.iuscommunity.org/pub/ius/stable/Redhat/7/x86_64/ius-release-1.0-14.ius.el7.noarch.rpm && \
 sed -i -e 's/enabled=1/enabled=0/' /etc/yum.repos.d/city-fan.org.repo \
  /etc/yum.repos.d/epel.repo \
  /etc/yum.repos.d/ius.repo && \
 yum install -y yum-utils file-roller firefox gedit git wget && \
 yum update -y --enablerepo=city-fan.org,epel,ius
```

General settings
+ Change SELinux "Permissive".
+ Set "Screen Lock" off.
+ Set "Purge Trush && Temporaries" on.
+ Set "Language" and "Format".
+ Set "Keyboard".
+ Set "Displays".
+ Set "Files preferences". 
+ Set "gEdit preferences".
