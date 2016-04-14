# CentOS 6
###### CentOS release 6.7 (Final)
## Using "Desktop" GUI after minimal installed.
Install required packages for Using Desktop.
```bash
yum groupinstall -y "Base" "Desktop" && \
 yum install -y nautilus-open-terminal
```
Change runlevel to "graphical".
```bash
# Change runlevel to "graphical". 
sed -i -e 's/id:[0-6]/id:5/' /etc/inittab

# And also, if you building Virtual Machine.
yum install -y open-vm-tools open-vm-tools-desktop
```
then "`shutdown -r now`".
#### And optional,
```bash
# change default Locale.
sed -i -e 's/LANG=*/LANG=[language_Country.Charset]/' /etc/sysconfig/i18n
localectl set-locale LANG=[language_Country.Charset]

# change default Timezone.
sed -i -e 's/^ZONE/ZONE=[Area]\/[Location]\n# ZONE/' /etc/sysconfig/clock && \
 /usr/sbin/tzdata-update
```

---
###### Notes: only for my own
```bash
# Install external repositories
yum install -y epel-release \
 http://www.city-fan.org/ftp/contrib/yum-repo/city-fan.org-release-1-13.rhel6.noarch.rpm \
 https://dl.iuscommunity.org/pub/ius/stable/Redhat/6/x86_64/ius-release-1.0-14.ius.el6.noarch.rpm \
 sed -i -e 's/enabled=1/enabled=0/g' /etc/yum.repos.d/city-fan.org.repo \
 sed -i -e 's/enabled=1/enabled=0/g' /etc/yum.repos.d/epel* \
 sed -i -e 's/enabled=1/enabled=0/g' /etc/yum.repos.d/ius* && \
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
+ Set "gedit preferences".
