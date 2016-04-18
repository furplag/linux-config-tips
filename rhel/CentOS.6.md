# CentOS 6
###### CentOS release 6.7 (Final)
## Using "Desktop" GUI after minimal installed.
##### Install required packages for Using Desktop.
```bash
yum groupinstall -y "Base" "Desktop" && \
 yum install -y nautilus-open-terminal
```
##### Change runlevel to "graphical".
```bash
# Change runlevel to "graphical". 
sed -i -e 's/id:[0-6]/id:5/' /etc/inittab
```

##### And also, if you building Virtual Machine.
```bash
yum install -y epel-release && \
 sed -i -e 's/enabled=1/enabled=0/g' /etc/yum.repos.d/epel* && \
yum install -y open-vm-tools open-vm-tools-desktop --enablerepo=epel
```

#### And optional,
```bash
# change default Locale.
sed -i -e 's/^LANG=/LANG="[language_Country.Charset]"\n\n#LANG=/' /etc/sysconfig/i18n

# change default Timezone.
sed -i -e 's/^ZONE=/ZONE="[Area]\/[Location]"\n#ZONE=/' /etc/sysconfig/clock && \
 /usr/sbin/tzdata-update
```
then "`shutdown -r now`".

### [That's it](https://git.io/vwqVh).
```bash
curl -fLs https://git.io/vmqay -o /tmp/quickstart.sh && \
 chmod +x /tmp/quickstart.sh && \
 /tmp/quickstart.sh
```

---
###### Notes: only for my own
```bash
# Install external repositories
yum install -y epel-release \
 http://www.city-fan.org/ftp/contrib/yum-repo/city-fan.org-release-1-13.rhel6.noarch.rpm \
 https://dl.iuscommunity.org/pub/ius/stable/Redhat/6/x86_64/ius-release-1.0-14.ius.el6.noarch.rpm && \
 sed -i -e 's/enabled=1/enabled=0/g' /etc/yum.repos.d/city-fan.org.repo \
  /etc/yum.repos.d/epel* \
  /etc/yum.repos.d/ius* && \
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
