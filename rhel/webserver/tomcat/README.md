# Tomcat on RHEL

## TL;DR
1. [Download Tomcat](#1-download-tomcat).
2. [Install Commons Daemon](#2-install-commons-daemon).
3. [Install Tomcat Native](#3-install-tomcat-native).
4. [Building Structure](#4-building-structure).
5. [Set tomcat as a Service](#5-set-tomcat-as-a-service).
6. Enable Tomcat Manager.
7. SSL setting with APR.

### Prerequirement
- [ ] All commands need you are "root" or you listed in "wheel".
- [ ] Java already installed (or not, [here](../../java)) .
- [ ] User named "tomcat" exists.

### 1. Download Tomcat
#### Download from URL (http://archive.apache.org/dist/tomcat) .
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

### 2. Install Commons Daemon
Here's a walkthrough.    
  1. Get Commons Daemon.    
  1. build Commons-daemon as "jsvc".    
  1. Set "jsvc" Tomcat's "bin" directory.    

#### Get commons-daemon-native.
commons-daemon-native.tar.gz is in [path-to-tomcat-source]/bin .    
Or Download from URL (http://archive.apache.org/dist/commons/daemon/source) .
```bash
curl -LO http://archive.apache.org/dist/commons/daemon/source/commons-daemon-[v.e.r]-src.tar.gz
```
Then extract.
```bash
tar xf commons-daemon(-[v.e.r])-native(-src).tar.gz
```

#### Install dependency packages (automake, gcc) .
```bash
yum install -y automake gcc
```

#### Configuration for build.
```bash
cd commons-daemon-[v.e.r]-native-src/unix && \
./configure \
  --prefix=/usr \
  --libdir=/usr/lib64 \
  --with-java=$JAVA_HOME && \
make
```

#### Install.
```bash
  mv jsvc [path-to-tomcat-source]/bin/jsvc && \
  chmod +x [path-to-tomcat-source]/bin/jsvc
```

### 3. Install Tomcat Native
Here's a walkthrough.    
    1. Get Tomcat Native source.    
    1. Build Tomcat Native.    
    1. Install Tomcat Native Library.    

#### Get tomcat-native.
tomcat-native.tar.gz is in [path-to-tomcat-source]/bin .    
Or Download from URL (http://archive.apache.org/dist/commons/daemon/source) .

Tomcat Native 1.2.x needs __APR 1.4.3__ or later.

Tomcat Native 1.2.x needs __OpenSSL 1.0.2__ or later.

```bash
curl -LO http://archive.apache.org/dist/tomcat/tomcat-connectors/native/[v.e.r]/source/tomcat-native-[v.e.r]-src.tar.gz
```
Then extract.
```bash
tar xf tomcat-native(-[v.e.r]-src).tar.gz
```

#### Install APR 1.5 from IUS Community.
##### In case RHEL6.
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

##### In case RHEL7.
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

#### Install OpenSSL-devel.
```bash
yum install -y openssl-devel
```
[See this](../apache/README.md#1-install-openssl-102) if you need install OpenSSL 1.0.2.

#### Configuration for build.

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


### 4. Building structure
Here's a walkthrough.

Situations:  

* "Tomcat version" is "8.0.36" .

* "Java version" is "8u92 (JAVA_HOME=/usr/java/jdk1.8.0_92)" .

* "TOMCAT_HOME" is directory `/usr/share/tomcat8` .

* "tomcat" run as user "tomcat" .

* user "tomcat" belong to group "tomcat" .

#### Set Tomcat directory.
```bash
mv [tomcat-source] /usr/share/tomcat8
rm -rf /usr/share/tomcat8/{logs,temp,work}
mkdir -p /usr/share/tomcat8/conf/Catalina/localhost
chown root:tomcat -R /usr/share/tomcat8
chmod 0775 -R /usr/share/tomcat8
```

#### Setting for directory "bin" .
```bash
rm -rf /usr/share/tomcat8/bin/*.bat
```

#### Setting for directory "conf" .
```bash
mv /usr/share/tomcat8/conf /etc/tomcat8
ln -s /etc/tomcat8 /usr/share/tomcat8/conf
```

#### Setting for directory "logs" .
```bash
mkdir -p /var/log/tomcat8
chown tomcat:tomcat /var/log/tomcat8
ln -s /var/log/tomcat8 /usr/share/tomcat8/logs
```

#### Setting for directory "temp, work" .
```bash
mkdir -p /var/cache/tomcat8/{temp,work}
ln -s /var/cache/tomcat8/temp /usr/share/tomcat8/temp
ln -s /var/cache/tomcat8/work /usr/share/tomcat8/work
```

#### Setting for directory "webapps" .
```bash
mkdir -p /var/lib/tomcat8
mv /usr/share/tomcat8/webapps /var/lib/tomcat8/webapps
ln -s /var/lib/tomcat8/webapps /usr/share/tomcat8/webapps
```

#### Setting for "pidfile" .
```bash
mkdir -p /var/run/tomcat
ln -s /var/run/tomcat /usr/share/tomcat8/run
```

#### Set permissions.
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

## pid(s)
chown tomcat:tomcat /var/run/tomcat
chmod 0775 /var/run/tomcat
```


### 5. Set tomcat as a Service
##### create file "[/etc/sysconfig/tomcat8](sysconfig.tomcat8)" (Permission: root:tomcat 0664) .
##### Create file "[/etc/tomcat8/tomcat8.conf](tomcat8.conf)" (Permission: tomcat:tomcat 0664) .
#### In case RHEL6 (service) .
##### Create file "[/etc/rc.d/init.d/tomcat8](tomcat8.service)" (Permission: root:root 0775) .
##### Test.
```bash
service tomcat8 configtest && service tomcat8 start
```

### [Install Tomcat on RHEL6](tomcat.install.el6.sh).

### [Install Tomcat on RHEL7](tomcat.install.el7.sh).
