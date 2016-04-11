# CentOS 7

## Install "Minimal Desktop" in CentOS 7

Install required packages for Using Desktop.
```bash
yum groupinstall -y "X Window System" && \
 yum install -y control-center \
 gnome-classic-session \
 gnome-terminal \
 nautilus-open-terminal
```

then
```bash
startx
```
or
```bash
# Change runlevel to "graphical". 
systemctl set-default graphical.target
```

> ### And also, if you building Virtual Machine
```bash
yum install -y open-vm-tools
```

#### and Optional
> Recommend: to use "Settings" in Desktop.

```bash
# change default Locale.
localectl set-locale LANG=[language_Country.Charset]

# change default Timezone.
datetimectl set-timezone [zoneinfo]
```
=


> ### Notes: only for my own

```bash
# Install external repositories
yum install -y epel-release \
 http://www.city-fan.org/ftp/contrib/yum-repo/city-fan.org-release-1-13.rhel7.noarch.rpm \
 https://dl.iuscommunity.org/pub/ius/stable/Redhat/7/x86_64/ius-release-1.0-14.ius.el7.noarch.rpm \
 http://nginx.org/packages/rhel/7/noarch/RPMS/nginx-release-rhel-7-0.el7.ngx.noarch.rpm && \
 sed -i -e 's/enapled=1/enapled=0/' /etc/yum.repos.d/city-fan.org.repo && \
 sed -i -e 's/enapled=1/enapled=0/' /etc/yum.repos.d/epel.repo && \
 sed -i -e 's/enapled=1/enapled=0/' /etc/yum.repos.d/ius.repo && \
 sed -i -e 's/enapled=1/enapled=0/' /etc/yum.repos.d/nginx.repo && \
 cp -p /etc/yum.repos.d/nginx.repo /etc/yum.repos.d/nginx-mainline.repo && \
 sed -i -e 's/\[nginx\]/\[nginx-mainline\]/' /etc/yum.repos.d/nginx-mainline.repo && \
 sed -i -e 's/\/packages\//\/packages\/mainline\//' /etc/yum.repos.d/nginx-mainline.repo && \
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
