# Install Oracle JDK 8 with alternatives
###### Oracle JDK 1.8.0_92

## Getting start

1. [Downloading Oracle JDK only use command-line.](#downloading-oracle-jdk-only-use-command-line)

2. [Install Oracle JDK 8.](#install-oracle-jdk)

3. [Install "alternatives" for JDK 8.](#install-alternatives-for-jdk)

4. [Set Environment with alternatives for Java VM.](#set-environment-java_home-for-java)

5. [Usage](#usage)

6. **[Quickstart](#thats-it)**

7. [Throuble shooting](#throuble-shooting)

----

### Downloading Oracle JDK only use command-line.
curl:
```bash
curl -fjkL https://edelivery.oracle.com/otn-pub/java/jdk/8u92-b14/jdk-8u92-linux-x64.rpm \
 -H "Cookie: oraclelicense=accept-securebackup-cookie" \
 -O
```

wget:
```bash
wget http://download.oracle.com/otn-pub/java/jdk/8u92-b14/jdk-8u92-linux-x64.rpm \
 --no-check-certificate \
 --no-cookies \
 --header "Cookie: oraclelicense=accept-securebackup-cookie"
```

### Install Oracle JDK.
```bash
yum install -y jdk-8u92-linux-x64.rpm
```

### Install "alternatives" for JDK.
```bash
# Remove alternatives for jre8 (optional).
alternatives --remove java /usr/java/jdk1.8.0_92/jre/bin/java
alternatives --install /usr/bin/java java /usr/java/jdk1.8.0_92/bin/java 180092 \
 --slave /usr/bin/appletviewer appletviewer /usr/java/jdk1.8.0_92/bin/appletviewer \
 --slave /usr/bin/extcheck extcheck /usr/java/jdk1.8.0_92/bin/extcheck \
 --slave /usr/bin/idlj idlj /usr/java/jdk1.8.0_92/bin/idlj \
 --slave /usr/bin/jar jar /usr/java/jdk1.8.0_92/bin/jar \
 --slave /usr/bin/jarsigner jarsigner /usr/java/jdk1.8.0_92/bin/jarsigner \
 --slave /usr/bin/javac javac /usr/java/jdk1.8.0_92/bin/javac \
 --slave /usr/bin/javadoc javadoc /usr/java/jdk1.8.0_92/bin/javadoc \
 --slave /usr/bin/javafxpackager javafxpackager /usr/java/jdk1.8.0_92/bin/javafxpackager \
 --slave /usr/bin/javah javah /usr/java/jdk1.8.0_92/bin/javah \
 --slave /usr/bin/javap javap /usr/java/jdk1.8.0_92/bin/javap \
 --slave /usr/bin/javapackager javapackager /usr/java/jdk1.8.0_92/bin/javapackager \
 --slave /usr/bin/java-rmi.cgi java-rmi.cgi /usr/java/jdk1.8.0_92/bin/java-rmi.cgi \
 --slave /usr/bin/jcmd jcmd /usr/java/jdk1.8.0_92/bin/jcmd \
 --slave /usr/bin/jconsole jconsole /usr/java/jdk1.8.0_92/bin/jconsole \
 --slave /usr/bin/jdb jdb /usr/java/jdk1.8.0_92/bin/jdb \
 --slave /usr/bin/jdeps jdeps /usr/java/jdk1.8.0_92/bin/jdeps \
 --slave /usr/bin/jhat jhat /usr/java/jdk1.8.0_92/bin/jhat \
 --slave /usr/bin/jinfo jinfo /usr/java/jdk1.8.0_92/bin/jinfo \
 --slave /usr/bin/jmap jmap /usr/java/jdk1.8.0_92/bin/jmap \
 --slave /usr/bin/jmc jmc /usr/java/jdk1.8.0_92/bin/jmc \
 --slave /usr/bin/jmc.ini jmc.ini /usr/java/jdk1.8.0_92/bin/jmc.ini \
 --slave /usr/bin/jps jps /usr/java/jdk1.8.0_92/bin/jps \
 --slave /usr/bin/jrunscript jrunscript /usr/java/jdk1.8.0_92/bin/jrunscript \
 --slave /usr/bin/jsadebugd jsadebugd /usr/java/jdk1.8.0_92/bin/jsadebugd \
 --slave /usr/bin/jstack jstack /usr/java/jdk1.8.0_92/bin/jstack \
 --slave /usr/bin/jstat jstat /usr/java/jdk1.8.0_92/bin/jstat \
 --slave /usr/bin/jstatd jstatd /usr/java/jdk1.8.0_92/bin/jstatd \
 --slave /usr/bin/jvisualvm jvisualvm /usr/java/jdk1.8.0_92/bin/jvisualvm \
 --slave /usr/bin/native2ascii native2ascii /usr/java/jdk1.8.0_92/bin/native2ascii \
 --slave /usr/bin/rmic rmic /usr/java/jdk1.8.0_92/bin/rmic \
 --slave /usr/bin/schemagen schemagen /usr/java/jdk1.8.0_92/bin/schemagen \
 --slave /usr/bin/serialver serialver /usr/java/jdk1.8.0_92/bin/serialver \
 --slave /usr/bin/wsgen wsgen /usr/java/jdk1.8.0_92/bin/wsgen \
 --slave /usr/bin/wsimport wsimport /usr/java/jdk1.8.0_92/bin/wsimport \
 --slave /usr/bin/xjc xjc /usr/java/jdk1.8.0_92/bin/xjc \
 --slave /usr/bin/ControlPanel ControlPanel /usr/java/jdk1.8.0_92/jre/bin/ControlPanel \
 --slave /usr/bin/javaws javaws /usr/java/jdk1.8.0_92/jre/bin/javaws \
 --slave /usr/bin/jcontrol jcontrol /usr/java/jdk1.8.0_92/jre/bin/jcontrol \
 --slave /usr/bin/jjs jjs /usr/java/jdk1.8.0_92/jre/bin/jjs \
 --slave /usr/bin/keytool keytool /usr/java/jdk1.8.0_92/jre/bin/keytool \
 --slave /usr/bin/orbd orbd /usr/java/jdk1.8.0_92/jre/bin/orbd \
 --slave /usr/bin/pack200 pack200 /usr/java/jdk1.8.0_92/jre/bin/pack200 \
 --slave /usr/bin/policytool policytool /usr/java/jdk1.8.0_92/jre/bin/policytool \
 --slave /usr/bin/rmid rmid /usr/java/jdk1.8.0_92/jre/bin/rmid \
 --slave /usr/bin/rmiregistry rmiregistry /usr/java/jdk1.8.0_92/jre/bin/rmiregistry \
 --slave /usr/bin/servertool servertool /usr/java/jdk1.8.0_92/jre/bin/servertool \
 --slave /usr/bin/tnameserv tnameserv /usr/java/jdk1.8.0_92/jre/bin/tnameserv \
 --slave /usr/bin/unpack200 unpack200 /usr/java/jdk1.8.0_92/jre/bin/unpack200
```

### Set Environment "$JAVA_HOME" for `java`.
```bash
[ ! -e /etc/proofile.d/java.sh ] && \
 cat <<_EOT_ > /etc/profile.d/java.sh
#/etc/profile.d/java.sh

# Set Environment with alternatives for Java VM.
export JAVA_HOME=\$(readlink /etc/alternatives/java | sed -e 's/\/bin\/java//g')

_EOT_
```
### [That's It.](jdk.install.sh)
```bash
curl https://raw.githubusercontent.com/furplag/linux-config-tips/master/rhel/java/jdk.install.sh \
 -o /tmp/jdk.install.sh && \
 chmod +x /tmp/jdk.install.sh && \
 /tmp/jdk.install.sh

# use "v" option if you need to install another version of JDK 8.
# e.g. /tmp/jdk.install.sh -v 8u77-b03

# use "m" option if you need to install maven. 
# e.g. /tmp/jdk.install.sh -m
```
---

### Usage
###### Remember, do not forget reload Environment after "alternatives" changed.
```bash
alternatives --set java /usr/java/jdk1.8.0_92/bin/java && source /etc/profile

# or select manually.
alternatives --config java && source /etc/profile

# Test
alternatives --display java | grep -e "^\/usr\/java/.*\/bin\/java" \
 | sed -e "s@`readlink /etc/alternatives/java`.*@\0 [selected]@" && \
java -version && \
echo -e "\$JAVA_HOME=${JAVA_HOME}"
```
---

## Throuble shooting

### Error: Permission denied.
**You need to be root to perform this command.** hint:`sudo`.

### Error: wget: command not found.
`yum install -y wget` or use `curl`.

### yum (or rpm) says "[upper version of jdk] already installed".
#### 1. Source install
```bash
curl -fjkL https://edelivery.oracle.com/otn-pub/java/jdk/8u92-b14/jdk-8u92-linux-x64.tar.gz \
 -H "Cookie: oraclelicense=accept-securebackup-cookie" \
 -O
```
#### 2. Unpacking
```bash
[ -e /usr/java ] || mkdir /usr/java
tar zxf jdk-8u92-linux-x64.tar.gz -C /usr/java
```
and continuing **[next](#install-alternatives-for-jdk)**.

### Could install another version of JDK 8?
[Use this](jdk.install.sh).
