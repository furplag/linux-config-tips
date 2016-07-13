# Tomcat on RHEL

## Getting Start
1. [Download Tomcat](#1-download-tomcat).
1. [Install Commons Daemon](#2-install-commons-daemon).
1. [Install Tomcat Native](#3-install-tomcat-native).
1. Set tomcat as a Service.
1. Enable Tomcat Manager.
1. SSL setting with APR.

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

#### Congiguration for build.
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

#### Congiguration for build.

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
Tomcat Native installed in /usr/lib64/libtcnative*




### [Install Tomcat on RHEL6](tomcat.install.el6.sh).

### [Install Tomcat on RHEL7](tomcat.install.el7.sh).
