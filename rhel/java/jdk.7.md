# Install Oracle JDK 7 with alternatives
###### Oracle JDK 1.7.0_80

## Getting start

1. [Downloading Oracle JDK only use command-line.](#downloading-oracle-jdk-only-use-command-line)

2. [Install Oracle JDK 7.](#install-oracle-jdk)

3. [Install "alternatives" for JDK 7.](#install-alternatives-for-jdk)

4. [Set Environment with alternatives for Java VM.](#set-environment-java_home-for-java)

5. [Usage](#usage)

6. **[Quickstart](#thats-it)**

7. [Throuble shooting](#throuble-shooting)

----

### Downloading Oracle JDK only use command-line.
```bash
wget http://download.oracle.com/otn-pub/java/jdk/7u80-b15/jdk-7u80-linux-x64.rpm \
 --no-check-certificate \
 --no-cookies \
 --header "Cookie: oraclelicense=accept-securebackup-cookie"
```

### Install Oracle JDK.
```bash
yum install -y jdk-7u80-linux-x64.rpm
```

### Install "alternatives" for JDK.
```bash
alternatives --install /usr/bin/java java /usr/java/jdk1.7.0_80/bin/java 170080 \
 --slave /usr/bin/appletviewer appletviewer /usr/java/jdk1.7.0_80/bin/appletviewer \
 --slave /usr/bin/extcheck extcheck /usr/java/jdk1.7.0_80/bin/extcheck \
 --slave /usr/bin/idlj idlj /usr/java/jdk1.7.0_80/bin/idlj \
 --slave /usr/bin/jar jar /usr/java/jdk1.7.0_80/bin/jar \
 --slave /usr/bin/jarsigner jarsigner /usr/java/jdk1.7.0_80/bin/jarsigner \
 --slave /usr/bin/javac javac /usr/java/jdk1.7.0_80/bin/javac \
 --slave /usr/bin/javadoc javadoc /usr/java/jdk1.7.0_80/bin/javadoc \
 --slave /usr/bin/javafxpackager javafxpackager /usr/java/jdk1.7.0_80/bin/javafxpackager \
 --slave /usr/bin/javah javah /usr/java/jdk1.7.0_80/bin/javah \
 --slave /usr/bin/javap javap /usr/java/jdk1.7.0_80/bin/javap \
 --slave /usr/bin/javapackager javapackager /usr/java/jdk1.7.0_80/bin/javapackager \
 --slave /usr/bin/java-rmi.cgi java-rmi.cgi /usr/java/jdk1.7.0_80/bin/java-rmi.cgi \
 --slave /usr/bin/jcmd jcmd /usr/java/jdk1.7.0_80/bin/jcmd \
 --slave /usr/bin/jconsole jconsole /usr/java/jdk1.7.0_80/bin/jconsole \
 --slave /usr/bin/jdb jdb /usr/java/jdk1.7.0_80/bin/jdb \
 --slave /usr/bin/jdeps jdeps /usr/java/jdk1.7.0_80/bin/jdeps \
 --slave /usr/bin/jhat jhat /usr/java/jdk1.7.0_80/bin/jhat \
 --slave /usr/bin/jinfo jinfo /usr/java/jdk1.7.0_80/bin/jinfo \
 --slave /usr/bin/jmap jmap /usr/java/jdk1.7.0_80/bin/jmap \
 --slave /usr/bin/jmc jmc /usr/java/jdk1.7.0_80/bin/jmc \
 --slave /usr/bin/jmc.ini jmc.ini /usr/java/jdk1.7.0_80/bin/jmc.ini \
 --slave /usr/bin/jps jps /usr/java/jdk1.7.0_80/bin/jps \
 --slave /usr/bin/jrunscript jrunscript /usr/java/jdk1.7.0_80/bin/jrunscript \
 --slave /usr/bin/jsadebugd jsadebugd /usr/java/jdk1.7.0_80/bin/jsadebugd \
 --slave /usr/bin/jstack jstack /usr/java/jdk1.7.0_80/bin/jstack \
 --slave /usr/bin/jstat jstat /usr/java/jdk1.7.0_80/bin/jstat \
 --slave /usr/bin/jstatd jstatd /usr/java/jdk1.7.0_80/bin/jstatd \
 --slave /usr/bin/jvisualvm jvisualvm /usr/java/jdk1.7.0_80/bin/jvisualvm \
 --slave /usr/bin/native2ascii native2ascii /usr/java/jdk1.7.0_80/bin/native2ascii \
 --slave /usr/bin/rmic rmic /usr/java/jdk1.7.0_80/bin/rmic \
 --slave /usr/bin/schemagen schemagen /usr/java/jdk1.7.0_80/bin/schemagen \
 --slave /usr/bin/serialver serialver /usr/java/jdk1.7.0_80/bin/serialver \
 --slave /usr/bin/wsgen wsgen /usr/java/jdk1.7.0_80/bin/wsgen \
 --slave /usr/bin/wsimport wsimport /usr/java/jdk1.7.0_80/bin/wsimport \
 --slave /usr/bin/xjc xjc /usr/java/jdk1.7.0_80/bin/xjc \
 --slave /usr/bin/ControlPanel ControlPanel /usr/java/jdk1.7.0_80/jre/bin/ControlPanel \
 --slave /usr/bin/javaws javaws /usr/java/jdk1.7.0_80/jre/bin/javaws \
 --slave /usr/bin/jcontrol jcontrol /usr/java/jdk1.7.0_80/jre/bin/jcontrol \
 --slave /usr/bin/jjs jjs /usr/java/jdk1.7.0_80/jre/bin/jjs \
 --slave /usr/bin/keytool keytool /usr/java/jdk1.7.0_80/jre/bin/keytool \
 --slave /usr/bin/orbd orbd /usr/java/jdk1.7.0_80/jre/bin/orbd \
 --slave /usr/bin/pack200 pack200 /usr/java/jdk1.7.0_80/jre/bin/pack200 \
 --slave /usr/bin/policytool policytool /usr/java/jdk1.7.0_80/jre/bin/policytool \
 --slave /usr/bin/rmid rmid /usr/java/jdk1.7.0_80/jre/bin/rmid \
 --slave /usr/bin/rmiregistry rmiregistry /usr/java/jdk1.7.0_80/jre/bin/rmiregistry \
 --slave /usr/bin/servertool servertool /usr/java/jdk1.7.0_80/jre/bin/servertool \
 --slave /usr/bin/tnameserv tnameserv /usr/java/jdk1.7.0_80/jre/bin/tnameserv \
 --slave /usr/bin/unpack200 unpack200 /usr/java/jdk1.7.0_80/jre/bin/unpack200
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
### [That's It.](jdk.7.install.sh)
```bash
wget https://raw.githubusercontent.com/furplag/linux-config-tips/master/rhel/java/jdk.7.install.sh \
 -qO /tmp/jdk.7.install.sh && \
 chmod +x /tmp/jdk.7.install.sh && \
 /tmp/jdk.7.install.sh
```
---

### Usage
###### Remember, do not forget reload Environment after "alternatives" changed.
```bash
alternatives --set java /usr/java/jdk1.7.0_80/bin/java && source /etc/profile

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
wget http://download.oracle.com/otn-pub/java/jdk/7u80-b15/jdk-7u80-linux-x64.tar.gz \
 --no-check-certificate \
 --no-cookies \
 --header "Cookie: oraclelicense=accept-securebackup-cookie"
```
#### 2. Unpacking
```bash
tar zxf jdk-7u80-linux-x64.tar.gz && \
 [ ! -e /usr/java ] && mkdir -p /usr/java && \
 mv jdk1.7.0_80 /usr/java/.
```
and continuing **[next](#install-alternatives-for-jdk)**.

### Could install another version of JDK 7?
Need to sign in Oracle. Download JDK 7 manually (with web browser).
