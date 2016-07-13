# Tomcat on RHEL

## TL;DR
1. [Download Tomcat](#1-download-tomcat).
2. [Enable Tomcat run as daemon](#2-build-commons-daemon).
3. [Install Tomcat Native](#3-install-tomcat-native).
4. Set tomcat as a Service.
5. Enable Tomcat Manager.
6. SSL setting with APR.

### 1. Download Tomcat
```bash
## e.g.
# curl -LO http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.36/bin/apache-tomcat-8.0.36.tar.gz
```

### 2. Build commons-daemon
Here's a walkthrough.
```bash
## 1. Install dependency packages.
# yum install -y automake gcc

## 2. Extract tomcat-source.tar.gz .
# tar xf apache-tomcat-[v.e.r].tar.gz

## 3. Then extract commons-daemon-native.tar.gz .
# tar xf [path-to-tomcat-source]/bin/commons-daemon-native.tar.gz

## 4. Congiguration for build.
# cd commons-daemon-[v.e.r]-native-src/unix
# ./configure \
  --prefix=/usr \
  --libdir=/usr/lib64 \
  --with-java=$JAVA_HOME && \
  make

## 5. Install.
  mv jsvc [path-to-tomcat-source]/bin/jsvc && \
  chmod +x [path-to-tomcat-source]/bin/jsvc
```

### 3. Install Tomcat Native
Here's a walkthrough.
```bash
## 1. Install dependency packages (1) .
# yum install -y automake gcc openssl-devel

## 2. Install dependency packages (2) .
##    Install APR version 1.4.3 or later.

##    Install APR 1.5 from IUS Community in RHEL6.
# yum install -y yum install -y -q https://dl.iuscommunity.org/pub/ius/stable/Redhat/6/x86_64/ius-release-1.0-14.ius.el6.noarch.rpm
# sed -i -e 's/enabled=1/enabled=0/g' /etc/yum.repos.d/ius*.repo
# yum install -y apr15u-devel --enablerepo=ius

##    Install APR 1.5 from IUS Community in RHEL7.
# yum install -y yum install -y -q https://dl.iuscommunity.org/pub/ius/stable/Redhat/7/x86_64/ius-release-1.0-14.ius.el7.noarch.rpm
# sed -i -e 's/enabled=1/enabled=0/g' /etc/yum.repos.d/ius*.repo
# yum install -y apr15u-devel --enablerepo=ius

## 3. Get tomcat-native.
## - tomcat-native.tar.gz is in [path-to-tomcat-source]/bin .
## - Or Download from URL (http://archive.apache.org/dist/tomcat/tomcat-connectors/native) .
# curl -LO http://archive.apache.org/dist/tomcat/tomcat-connectors/native/[v.e.r]/source/tomcat-native-[v.e.r]-src.tar.gz

## 2. Extract tomcat-source.tar.gz .
# tar xf apache-tomcat-[v.e.r].tar.gz

## 4. Extract tomcat-source/bin/tomcat-native.tar.gz .
# tar xf [path-to-tomcat-source]/bin/tomcat-native(-[v.e.r]-src).tar.gz

## 4. Congiguration for build.
# cd tomcat-native-[v.e.r]-src/native
# ./configure \
  --prefix=/usr \
  --libdir=/usr/lib64 \
  --with-java-home=$JAVA_HOME \
  --with-apr=/usr/bin/apr([15u])-1-config \
  --with-ssl=/usr/include/openssl
##  (add option "--disable-openssl-version-check" if your OpenSSL version is lower than 1.0.2.)

## 5. Install libtcnative.
#  make && make install
```

### [Install Tomcat on RHEL6](tomcat.install.el6.sh).

### [Install Tomcat on RHEL7](tomcat.install.el7.sh).
