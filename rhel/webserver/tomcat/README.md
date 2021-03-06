# Tomcat on RHEL

## TL;DR
1. [Download Tomcat](#1-download-tomcat).
2. [Install Commons Daemon](#2-install-commons-daemon).
3. [Install Tomcat Native](#3-install-tomcat-native).
4. [Building Structure](#4-building-structure).
5. [Set tomcat as a Service](#5-set-tomcat-as-a-service).
6. [Enable Tomcat Manager](#6-enable-tomcat-manager).
7. [More stuff](#7-more-stuff).
   1. using "catalina.properties" .
   2. Tomcat over SSL.

## Prerequirement
- [ ] All commands need you are "root" or you listed in "wheel" .
- [ ] Java already installed (or not, [see this](../../java)) .
- [ ] User named "tomcat" exists.
- [ ] Switch "permissive" SELinux.

____

## 1. Download Tomcat
### Download from URL (http://archive.apache.org/dist/tomcat) .
```bash
curl -LO http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.36/bin/apache-tomcat-8.0.36.tar.gz

## download @somewhere if you want,
curl -L http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.36/bin/apache-tomcat-[v.e.r].tar.gz \
  -o [path-here]/apache-tomcat-[v.e.r].tar.gz
```
Then extract.
```bash
## e.g.) unpack source to /usr/share/tomcat[ver].
tar xf apache-tomcat-8.0.36.tar.gz

## extract to dir "/usr/share/tomcat8" if you want,
tar xf apache-tomcat-8.0.36.tar.gz -C /usr/share && mv /usr/share/apache-tomcat-8.0.36 /usr/share/tomcat8
```
___


## 2. Install Commons Daemon
#### Overview
1. Get Commons Daemon.    
2. build Commons-daemon as "jsvc".    
3. Set "jsvc" Tomcat's "bin" directory.    

### Get commons-daemon-native.
commons-daemon-native.tar.gz is in [path-to-tomcat-source]/bin .    
Or Download from URL (http://archive.apache.org/dist/commons/daemon/source) .
```bash
curl -LO http://archive.apache.org/dist/commons/daemon/source/commons-daemon-[v.e.r]-src.tar.gz
```
#### Then extract.
```bash
tar xf commons-daemon(-[v.e.r])-native(-src).tar.gz
```

### Install dependency packages (automake, gcc) .
```bash
yum install -y automake gcc
```

### Configuration for build.
```bash
cd commons-daemon-[v.e.r]-native-src/unix && \
./configure \
  --prefix=/usr \
  --libdir=/usr/lib64 \
  --with-java=$JAVA_HOME && \
make
```

### Install.
```bash
  mv jsvc [path-to-tomcat-source]/bin/jsvc && \
  chmod +x [path-to-tomcat-source]/bin/jsvc
```
___


## 3. Install Tomcat Native
#### Overview
1. Get Tomcat Native source.    
2. Build Tomcat Native.    
3. Install Tomcat Native Library.    

### Get tomcat-native.
tomcat-native.tar.gz is in [path-to-tomcat-source]/bin .    
Or Download from URL (http://archive.apache.org/dist/commons/daemon/source) .

Tomcat Native 1.2.x needs __APR 1.4.3__ or later.

Tomcat Native 1.2.x needs __OpenSSL 1.0.2__ or later.

```bash
curl -LO http://archive.apache.org/dist/tomcat/tomcat-connectors/native/[v.e.r]/source/tomcat-native-[v.e.r]-src.tar.gz
```
#### Then extract.
```bash
tar xf tomcat-native(-[v.e.r]-src).tar.gz
```

### Install APR 1.5 from IUS Community.
#### In case RHEL6.
Install ius repository.
```bash
yum install -y \
  https://dl.iuscommunity.org/pub/ius/stable/Redhat/6/x86_64/ius-release-1.0-14.ius.el6.noarch.rpm && \
sed -i -e 's/enabled=1/enabled=0/g' /etc/yum.repos.d/ius*.repo
```
Install APR.
```bash
yum install -y apr15u-util apr15u-devel --enablerepo=ius
```

#### In case RHEL7.
> RHEL7 has already updated APR version 1.4.3.

Install ius repository.
```bash
yum install -y \
  https://dl.iuscommunity.org/pub/ius/stable/Redhat/7/x86_64/ius-release-1.0-14.ius.el7.noarch.rpm && \
sed -i -e 's/enabled=1/enabled=0/g' /etc/yum.repos.d/ius*.repo
```
Install APR.
```bash
yum install -y apr15u-util apr15u-devel --enablerepo=ius
```

### Install OpenSSL-devel.
```bash
yum install -y openssl-devel
```
[See this](../apache/README.md#1-install-openssl-102) if you need install OpenSSL 1.0.2.

### Configuration for build.

Add option `--disable-openssl-version-check` if your __OpenSSL version is lower than 1.0.2__.
```bash
cd tomcat-native-[v.e.r]-src/native && \
./configure \
  --prefix=/usr \
  --libdir=/usr/lib64 \
  --with-java-home=$JAVA_HOME \
  --with-apr=/usr/bin/apr([15u])-1-config \
  --with-ssl=/usr/include/openssl && \
make && make install
```
Tomcat Native installed in /usr/lib64/libtcnative* .
___

## 4. Building structure
#### Here's a walkthrough.

Situations:  

* "Tomcat version" is "8.0.36" .

* "Java version" is "8u92 (JAVA_HOME=/usr/java/jdk1.8.0_92)" .

* "TOMCAT_HOME" is directory `/usr/share/tomcat8` .

* "tomcat" run as user "tomcat" .

* user "tomcat" belong to group "tomcat" .

### Set Tomcat directory.
```bash
mv [tomcat-source] /usr/share/tomcat8
rm -rf /usr/share/tomcat8/{logs,temp,work}
mkdir -p /usr/share/tomcat8/conf/Catalina/localhost
chown root:tomcat -R /usr/share/tomcat8
chmod 0775 -R /usr/share/tomcat8
```

### Setting for directory "bin" .
```bash
rm -rf /usr/share/tomcat8/bin/*.bat
```

### Setting for directory "conf" .
```bash
mv /usr/share/tomcat8/conf /etc/tomcat8
ln -s /etc/tomcat8 /usr/share/tomcat8/conf
```

### Setting for directory "logs" .
```bash
mkdir -p /var/log/tomcat8
chown tomcat:tomcat /var/log/tomcat8
ln -s /var/log/tomcat8 /usr/share/tomcat8/logs
```

### Setting for directory "temp, work" .
```bash
mkdir -p /var/cache/tomcat8/{temp,work}
ln -s /var/cache/tomcat8/temp /usr/share/tomcat8/temp
ln -s /var/cache/tomcat8/work /usr/share/tomcat8/work
```

### Setting for directory "instances" (in use multi instances) .
```bash
mkdir -p /var/lib/tomcat8s
mv /usr/share/tomcat8/webapps /var/lib/tomcat8/webapps
ln -s /var/lib/tomcat8s /usr/share/tomcat8/instances
```

### Setting for directory "webapps" .
```bash
mkdir -p /var/lib/tomcat8
mv /usr/share/tomcat8/webapps /var/lib/tomcat8/webapps
ln -s /var/lib/tomcat8/webapps /usr/share/tomcat8/webapps
```

### Setting for "pidfile" .
```bash
mkdir -p /var/run/tomcat
ln -s /var/run/tomcat /usr/share/tomcat8/run
```

### Set permissions.
```bash
## bin
chmod 0664 /usr/share/tomcat8/bin/*.*
chmod +x /usr/share/tomcat8/bin/{jsvc,*.sh}

## conf
chown tomcat:tomcat /etc/tomcat8/*.*
chmod 0664 /etc/tomcat8/*.*
chmod 0660 /etc/tomcat8/tomcat-users.xml

## logs
chmod 0770 /var/log/tomcat8

## temp, work
chown tomcat:tomcat -R /var/cache/tomcat8
chmod 0770 -R /var/cache/tomcat8

## webapps
chown tomcat:tomcat -R /var/lib/tomcat8
chmod 0770 /var/lib/tomcat8
chmod 0775 -R /var/lib/tomcat8/webapps

## instances
chown tomcat:tomcat /var/lib/tomcat8s
chmod 0775 /var/lib/tomcat8s

## pid(s)
chown tomcat:tomcat /var/run/tomcat
chmod 0775 /var/run/tomcat
```
___


## 5. Set tomcat as a Service
### Create file "[/etc/sysconfig/tomcat8](tomcat8.sysconfig)" (Permission: root:tomcat 0664) .
### Create file "[/etc/tomcat8/tomcat8.conf](tomcat8.conf.default)" (Permission: tomcat:tomcat 0664) .
Remember to fix "__JAVA_HOME=[java_home_of_your_machine]__".
### In case RHEL6 (service), create file "[/etc/rc.d/init.d/tomcat8](tomcat8.service)" (Permission: root:root 0775) .
### In case RHEL7 (systemctl),
#### Create file "[/usr/lib/systemd/system/tomcat.service](tomcat8.systemctl)" (Permission: root:root 0775) .
#### Create file "/usr/lib/systemd/system/tomcat@.service" (Permission: root:root 0775) .
```bash
cp -p /usr/lib/systemd/system/tomcat8.service \
/usr/lib/systemd/system/tomcat8@.service

sed -i -e "s/tomcat8@/\0name/g" \
-e 's/Environment="NAME=/\0\%I/g' \
-e "s/EnvironmentFile=-\/etc\/sysconfig\/tomcat8/\0@\%I/g" \
/usr/lib/systemd/system/tomcat8@.service
chmod 644 /usr/lib/systemd/system/tomcat8@.service
```
___


## 6. Enable Tomcat Manager
Here's a walkthrough.
```xml
<?xml version='1.0' encoding='utf-8'?>
<!--
  Licensed to the Apache Software Foundation (ASF) under one or more
  contributor license agreements.  See the NOTICE file distributed with
  this work for additional information regarding copyright ownership.
  The ASF licenses this file to You under the Apache License, Version 2.0
  (the "License"); you may not use this file except in compliance with
  the License.  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
-->
<tomcat-users xmlns="http://tomcat.apache.org/xml"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
  version="1.0">

  <!-- for /host-manager/html/* -->
  <role rolename="admin-gui" />

  <!-- for /host-manager/text/* -->
  <role rolename="admin-script" />

  <!-- for /manager/html/* -->
  <role rolename="manager-gui" /> 

  <!-- for /manager/jmxproxy/* -->
  <role rolename="manager-jmx" />

  <!-- for /manager/text/* -->
  <role rolename="manager-script" />

  <!-- for /manager/status/* -->
  <role rolename="manager-status" />

  <!-- like a GOD. -->
  <user username="[username]" password="[secret]" 
    roles="admin-gui,admin-script,manager-gui,manager-jmx,manager-script,manager-status" />
</tomcat-users>
```
____
## 7. More stuff
### Using "catalina.properties".
in "conf/catalina.properties"
```properties
server.port=8081
```
then modify "conf/server.xml"
```bash
sed -i -e 's/port="8080"/port="\${server.port}"/' [tomcat-directory]/conf/server.xml
```
### Tomcat over SSL with APR.
Adding Connector in conf/server.xml.
```xml
<Connector
  protocol="org.apache.coyote.http11.Http11AprProtocol"
  port="8443" maxThreads="200"
  scheme="https" secure="true" clientAuth="false" SSLEnabled="true"
  SSLCertificateFile="[path-to-certificate-file]"
  SSLCertificateKeyFile="[path-to-privatekey-file]"
  SSLProtocol="TLSv1+TLSv1.1+TLSv1.2">
<!-- enable HTTP/2, if you using Tomcat9. -->
<!--
  <UpgradeProtocol className="org.apache.coyote.http2.Http2Protocol" />
-->
</Connector>
```

If https://[your-tomcat-server]/manager returns 403, Add "RemoteAddrValve" to context 

as file "conf/Catalina/localhost/manager.xml" .

```xml
<Context privileged="true" antiResourceLocking="false"
  docBase="${catalina.home}/webapps/manager">
  <!-- allow public (DO NOT use production) . -->
  <Valve className="org.apache.catalina.valves.RemoteAddrValve" allow="^.*$" />
  <!-- localhost only -->
  <Valve className="org.apache.catalina.valves.RemoteAddrValve" allow="172\.0\.0\.1|::1|0:0:0:0:0:0:0:1" />

  <!-- allow from 192.168.124.* (VMWare NAT default) -->
  <Valve className="org.apache.catalina.valves.RemoteAddrValve" allow="172\.0\.0\.1|::1|0:0:0:0:0:0:0:1|192\.168\.124\.\d+" />
</Context>
```
____


## Quickstart
### [Install Tomcat on RHEL6](tomcat.install.el6.sh).
```bash
curl -LO https://raw.githubusercontent.com/furplag/linux-config-tips/master/rhel/webserver/tomcat/tomcat.install.el6.sh
## set variables you need.
chmod +x tomcat.install.el6.sh
./tomcat.install.el6.sh
```
### [Install Tomcat on RHEL7](tomcat.install.el7.sh).
```bash
curl -LO https://raw.githubusercontent.com/furplag/linux-config-tips/master/rhel/webserver/tomcat/tomcat.install.el7.sh
## set variables you need.
chmod +x tomcat.install.el7.sh
./tomcat.install.el7.sh
```
