# Tomcat on RHEL

[Druft]

## TL;DR
1. [Download Tomcat](#1-download-tomcat).
2. [Enable Tomcat run as daemon](#2-enable-tomcat-run-as-daemon).
3. [Install Tomcat Native](#3-install-tomcat-native).
4. [Set tomcat as a Service](#3-set-tomcat-as-a-service).
5. [Enable Tomcat Manager](#4-tomcat-manager).
6. [SSL setting with APR](#5-ssl-setting-with-apr).

## Getting start

### 1. Download Tomcat
Download tomcat-*-tar.gz from [Apache Tomcat](https://tomcat.apache.org/).
```bash
$ curl -LO http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.36/bin/apache-tomcat-8.0.36.tar.gz
```
then extract.

### 2. Enable Tomcat run as daemon
#### Requirement
- environment "[$JAVA_HOME](../../java)".
- dependency packages
  - automake `yum install -y automake`
  - gcc `yum install -y gcc`

#### building "jsvc".
commons-daemon-[version] is in [tomcat-directory]/bin/commons-daemon-native.tar.gz
building jsvc.
```bash
# tar xf [tomcat-directory]/bin/commons-daemon-native.tar.gz
# cd [extracted-source]/unix
# ./configure \
  --prefix=/usr \
  --libdir=/usr/lib64 \
  --with-java=$JAVA_HOME
# make
```
- move build outed "jsvc" to [tomcat-directory]/bin
- modify executable.

### 3. Install Apache 2.4 over SSL
Install Dependencies: Reopsitories (City-fan, IUS Community) .
```bash
# osVer=$(cat /etc/redhat-release | sed -n -e 1p | sed -e 's/^.*release *//' | cut -d '.' -f 1)
# yum install -y \
  https://dl.iuscommunity.org/pub/ius/stable/Redhat/$osVer/x86_64/ius-release-1.0-14.ius.$osVer.noarch.rpm \
  http://www.city-fan.org/ftp/contrib/yum-repo/city-fan.org-release-1-13.rhel$osVer.noarch.rpm && \
  sed -i -e 's/enabled=1/enabled=0/' /etc/yum.repos.d/{city-fan,ius}*.repo
```
Install Dependencies: APR (Apache Portable Runtime) (1.5 or later) from IUS Community.
```bash
# yum install -y -q apr15u apr15u-util --enablerepo=ius
```
then
```bash
# yum install -y httpd24u mod24u_ssl --enablerepo=city-fan.org,furplag.github.io
```
or `rpmbuild`.
```bash
# work in progress
```

## Quickstart
see [this](httpd24.install.sh).
```bash
# curl -LO https://raw.githubusercontent.com/furplag/linux-config-tips/master/rhel/java/httpd24.install.sh && \
  chmod +x httpd24.install.sh && \
  ./httpd24.install.sh
```
