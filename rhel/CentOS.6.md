# CentOS 6
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
and optional,
```bash
# change default Locale.
sed -i -e 's/LANG=*/LANG=[language_Country.Charset]/' /etc/sysconfig/i18n
localectl set-locale LANG=[language_Country.Charset]

# change default Timezone.
sed -i -e 's/^ZONE/ZONE=[Area]\/[Location]\n# ZONE/' /etc/sysconfig/clock && \
 /usr/sbin/tzdata-update
```

---
### Notes: only for my own
```bash
# Install external repositories
yum install -y epel-release \
 http://www.city-fan.org/ftp/contrib/yum-repo/city-fan.org-release-1-13.rhel6.noarch.rpm \
 https://dl.iuscommunity.org/pub/ius/stable/Redhat/6/x86_64/ius-release-1.0-14.ius.el6.noarch.rpm \
 http://nginx.org/packages/rhel/6/noarch/RPMS/nginx-release-rhel-6-0.el6.ngx.noarch.rpm && \
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
+ Set "gedit preferences".
