# CentOS 6
###### CentOS release 6.7 (Final)
## Using "Desktop" GUI after minimal installed.
##### Install required packages for Using Desktop.
```bash
yum groupinstall -y "Base" "Desktop" && \
 yum install -y yum-utils nautilus-open-terminal
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
curl -fLs https://git.io/vwOCy -o /tmp/quickstart.sh && \
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
 yum install -y file-roller firefox gedit git ntp wget && \
 yum update -y --enablerepo=city-fan.org,epel,ius

# Install open-vm-tools
yum install -y open-vm-tools open-vm-tools-desktop --enablerepo=epel
```

General settings (**Terminal in GUI Desktop**).
```bash
# General settings
## SELinux
sed -i -e 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

## Localize
yum groupinstall -y "Fonts" "Japanese Support" && \

# Language
if [ "${LANG}" != "ja_JP.UTF-8" ]; then
  sed -i -e 's/^./#\0/' -e '1i\LANG="ja_JP.UTF-8"\n' /etc/sysconfig/i18n
fi

# Input method
sed -i -e 's/^./#\0/g' /etc/sysconfig/keyboard && \
 cat << _EOT_ >> /etc/sysconfig/keyboard

KEYTABLE="jp106"
MODEL="jp106+inet"
LAYOUT="jp"
KEYBOARDTYPE="pc"

_EOT_

# Timezone
sed -i -e 's/^./#\0/' -e '1i\ZONE="Asia\/Tokyo"\n' /etc/sysconfig/clock && \
 /usr/sbin/tzdata-update

# NTP
sed -i \
 -e "s/^server/#server/" \
 -e "$(echo $(cat /etc/ntp.conf | grep -n -e "^server" | sed -n '$p' | sed -e 's/:.*//'))a\server -4 ntp.nict.jp\nserver 127.127.1.0\nfudge 127.127.1.0 stratum 10\n" \
 /etc/ntp.conf

chkconfig ntpd on
```
