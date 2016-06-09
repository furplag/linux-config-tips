#!/bin/bash

systemctl status tomcat9 >/dev/null && exit 0
currentDir=`pwd`

if ! grep -e "^tomcat" /etc/passwd >/dev/null; then
  echo "  create user: Tomcat (91)."
  useradd -u 91 tomcat -U -r -s /sbin/nologin
fi

if ! ls /usr/lib64 | grep tcnative >/dev/null; then
  echo "  install tomcat native ..."
  if [ $(rpm -qa automake gcc | wc -l) -ne 2 ]; then
    yum install -y -q automake gcc >/dev/null || exit 1
  fi
  yum install -y -q apr15u-devel --enablerepo=ius || yum install -y -q apr-devel exit 1
  yum install -y -q openssl-devel --enablerepo=furplag.github.io || yum install -y -q openssl-devel || exit 1

  curl -L http://archive.apache.org/dist/tomcat/tomcat-connectors/native/1.2.7/source/tomcat-native-1.2.7-src.tar.gz \
  -o /tmp/tomcat-native-1.2.7-src.tar.gz

  cd /tmp/tomcat-native-1.2.7-src/native
  ./configure \
  --prefix=/usr \
  --libdir=/usr/lib64 \
  --with-java-home=/usr/java/latest \
  --with-apr=/usr/bin/apr15u-1-config \
  --with-ssl=/usr/include/openssl && \
  make && make install && \
  cd "${currentDir}"  
  rm -rf /tmp/tomcat-native-1.2.7-src
fi

echo "  Downloading Tomcat ..."
curl -fjkL http://archive.apache.org/dist/tomcat/tomcat-9/v9.0.0.M6/bin/apache-tomcat-9.0.0.M6.tar.gz \
-o /tmp/apache-tomcat-9.0.0.M6.tar.gz
tar xf /tmp/apache-tomcat-9.0.0.M6.tar.gz -C /usr/share
mv /usr/share/apache-tomcat-9.0.0.M6.tar.gz /usr/share/tomcat9

echo "  install tomcat daemon ..."
if [ $(rpm -qa automake gcc | wc -l) -ne 2 ]; then
  yum install -y -q automake gcc >/dev/null || exit 1
fi
tar xf /usr/share/tomcat9/bin/commons-daemon-native.tar.gz -C /tmp
cd /tmp/commons-daemon-1.0.15-native-src/unix
./configure \
--prefix=/usr \
--libdir=/usr/lib64 \
--with-java=/usr/java/latest >/dev/null && \
make >/dev/null && \
cd "${currentDir}"
cp /tmp/commons-daemon-1.0.15-native-src/unix/jsvc /usr/share/tomcat9/bin/jsvc
rm -rf /tmp/commons-daemon-1.0.15-native-src/unix/jsvc 

echo "  building structure ..."
mkdir -p /usr/share/tomcat9/conf/Catalina/localhost
chown root:tomcat -R /usr/share/tomcat9
chmod 775 -R /usr/share/tomcat9
rm -rf /usr/share/tomcat9/{logs,temp,work}

# bin
rm -rf /usr/share/tomcat9/bin/*.bat
chmod 0664 /usr/share/tomcat9/bin/*.*
chmod +x /usr/share/tomcat9/bin/{jsvc,*.sh}

#conf
mv /usr/share/tomcat9/conf /etc/tomcat9
ln -s /etc/tomcat9 /usr/share/tomcat9/conf
chown tomcat:tomcat /etc/tomcat9/*.*
chmod 0664 /etc/tomcat9/*.*
chmod 0660 /etc/tomcat9/tomcat-users.xml

#logs
mkdir -p /var/log/tomcat9
chown tomcat:tomcat /var/log/tomcat9
chmod 0770 /var/log/tomcat9
ln -s /var/log/tomcat9 /usr/share/tomcat9/logs

#temp,work
mkdir -p /var/cache/tomcat9/{temp,work}
chown tomcat:tomcat -R /var/cache/tomcat9
chmod 0770 -R /var/cache/tomcat9
ln -s /var/cache/tomcat9/temp /usr/share/tomcat9/temp
ln -s /var/cache/tomcat9/work /usr/share/tomcat9/work

#webapps
mkdir -p /var/lib/tomcat9
mv /usr/share/tomcat9/webapps /var/lib/tomcat9/webapps
chown tomcat:tomcat -R /var/lib/tomcat9
chmod 0770 /var/lib/tomcat9
chmod 0775 -R /var/lib/tomcat9/webapps
ln -s /var/lib/tomcat9/webapps /usr/share/tomcat9/webapps

#instances
mkdir -p /var/lib/tomcat9s
chown tomcat:tomcat /var/lib/tomcat9s
chmod 0775 /var/lib/tomcat9s

touch /var/run/tomcat9.pid
chown tomcat:tomcat /var/run/tomcat9.pid
chmod 664 /var/run/tomcat9.pid

sed -i -e 's/Context antiResourceLocking="false"/Context antiResourceLocking="true"/' -e 's/<Context[^>]*>$/\0\n<!-- /' -e 's/<\/Context/ -->\n\0/' /usr/share/tomcat9/webapps/{host-manager,manager}/META-INF/context.xml
sed -i -e 's/<\/tomcat-users[^>]*>/<!-- \0 -->/' /usr/share/tomcat9/conf/tomcat-users.xml
cat <<_EOT_>> /usr/share/tomcat9/conf/tomcat-users.xml
  <role rolename="admin-gui" />
  <role rolename="admin-script" />
  <role rolename="manager-gui" />
  <role rolename="manager-jmx" />
  <role rolename="manager-script" />
  <role rolename="manager-status" />
  <user username="tomcat" password="tomcat" roles="admin-gui,manager-gui" />
</tomcat-users>

_EOT_

cat <<_EOT_> /etc/sysconfig/tomcat9
# Service-specific configuration file for tomcat. This will be sourced by
# the SysV init script after the global configuration file
# /etc/tomcat9/tomcat9.conf, thus allowing values to be overridden in
# a per-service manner.
#
# NEVER change the init script itself. To change values for all services make
# your changes in /etc/tomcat9/tomcat9.conf
#
# To change values for a specific service make your edits here.
# To create a new service create a link from /etc/init.d/<your new service> to
# /etc/init.d/tomcat9 (do not copy the init script) and make a copy of the
# /etc/sysconfig/tomcat9 file to /etc/sysconfig/<your new service> and change
# the property values so the two services won't conflict. Register the new
# service in the system as usual (see chkconfig and similars).
#

# Where your java installation lives
#JAVA_HOME="/usr/lib/jvm/java"

# Where your tomcat installation lives
#CATALINA_BASE="/usr/share/tomcat9"
#CATALINA_HOME="/usr/share/tomcat9"
#JASPER_HOME="/usr/share/tomcat9"
#CATALINA_TMPDIR="/var/cache/tomcat9/temp"

# You can pass some parameters to java here if you wish to
#JAVA_OPTS="-Xminf0.1 -Xmaxf0.3"

# Use JAVA_OPTS to set java.library.path for libtcnative.so
#JAVA_OPTS="-Djava.library.path=/usr/lib64"

# What user should run tomcat
#TOMCAT_USER="tomcat"

# You can change your tomcat locale here
#LANG="en_US"

# Run tomcat under the Java Security Manager
#SECURITY_MANAGER="false"

# Time to wait in seconds, before killing process
#SHUTDOWN_WAIT="30"

# Whether to annoy the user with "attempting to shut down" messages or not
#SHUTDOWN_VERBOSE="false"

# Set the TOMCAT_PID location
#CATALINA_PID="/var/run/tomcat9.pid"

# Connector port is 8080 for this tomcat instance
#CONNECTOR_PORT="8080"

# If you wish to further customize your tomcat environment,
# put your own definitions here
# (i.e. LD_LIBRARY_PATH for some jdbc drivers)

_EOT_
chown root:tomcat /etc/sysconfig/tomcat9
chmod 644 /etc/sysconfig/tomcat9

cat <<_EOT_> /etc/tomcat9/tomcat9.conf
# System-wide configuration file for tomcat services
# This will be loaded by systemd as an environment file,
# so please keep the syntax.
#
# There are 2 "classes" of startup behavior in this package.
# The old one, the default service named tomcat.service.
# The new named instances are called tomcat9@instance.service.
#
# Use this file to change default values for all services.
# Change the service specific ones to affect only one service.
# For tomcat9.service it's /etc/sysconfig/tomcat9, for
# tomcat9@instance it's /etc/sysconfig/tomcat9@instance.

# This variable is used to figure out if config is loaded or not.
TOMCAT_CFG_LOADED="1"

# In new-style instances, if CATALINA_BASE isn't specified, it will
# be constructed by joining TOMCATS_BASE and NAME.
TOMCATS_BASE="/var/lib/tomcat9s/"

# Where your java installation lives
JAVA_HOME="${JAVA_HOME}"

# Where your tomcat installation lives
CATALINA_HOME="/usr/share/tomcat9"

# System-wide tmp
CATALINA_TMPDIR="/var/cache/tomcat9/temp"

# You can pass some parameters to java here if you wish to
#JAVA_OPTS="-Xminf0.1 -Xmaxf0.3"

# Use JAVA_OPTS to set java.library.path for libtcnative.so
#JAVA_OPTS="-Djava.library.path=/usr/lib"

# You can change your tomcat locale here
#LANG="en_US"

# Run tomcat under the Java Security Manager
SECURITY_MANAGER="false"

# Time to wait in seconds, before killing process
# TODO(stingray): does nothing, fix.
# SHUTDOWN_WAIT="30"

# If you wish to further customize your tomcat environment,
# put your own definitions here
# (i.e. LD_LIBRARY_PATH for some jdbc drivers)
CATALINA_OPTS="-server -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Dfile.encoding=utf-8"
CATALINA_OPTS="-Xms512m -Xmx1g -XX:PermSize=256m -XX:MaxPermSize=1g -XX:NewSize=128m"
CATALINA_OPTS="-Xloggc:/usr/share/tomcat9/logs/gc.log -XX:+PrintGCDetails"
CATALINA_OPTS="-Djava.security.egd=file:/dev/./urandom"

_EOT_
chown tomcat:tomcat /etc/tomcat9/tomcat9.conf
chmod 664 /etc/tomcat9/tomcat9.conf

cat <<_EOT_> /usr/lib/systemd/system/tomcat9.service
# Systemd unit file for default tomcat
# 
# To create clones of this service:
# DO NOTHING, use tomcat9@.service instead.

[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target

[Service]
Type=forking
EnvironmentFile=/etc/tomcat9/tomcat9.conf
Environment="NAME="
EnvironmentFile=-/etc/sysconfig/tomcat9

# replace "ExecStart" and "ExecStop" if you want tomcat runs as daemon
# ExecStart=/usr/share/tomcat9/bin/daemon.sh start
# ExecStop=/usr/share/tomcat9/bin/daemon.sh stop
ExecStart=/usr/share/tomcat9/bin/startup.sh
ExecStop=/usr/share/tomcat9/bin/shutdown.sh

SuccessExitStatus=143
User=tomcat
Group=tomcat

[Install]
WantedBy=multi-user.target

_EOT_
chmod 644 /usr/lib/systemd/system/tomcat9.service

cat <<_EOT_> /usr/lib/systemd/system/tomcat9@.service
# Systemd unit file for tomcat instances.
# 
# To create clones of this service:
# 0. systemctl enable tomcat9@name.service
# 1. create catalina.base directory structure in
#    /var/lib/tomcat9s/name
# 2. profit.

[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target

[Service]
Type=forking
EnvironmentFile=/etc/tomcat9/tomcat9.conf
Environment="NAME=%I"
EnvironmentFile=-/etc/sysconfig/tomcat9@%I

# replace "ExecStart" and "ExecStop" if you want tomcat runs as daemon
# ExecStart=/usr/share/tomcat9/bin/daemon.sh start
# ExecStop=/usr/share/tomcat9/bin/daemon.sh stop
ExecStart=/usr/share/tomcat9/bin/startup.sh
ExecStop=/usr/share/tomcat9/bin/shutdown.sh

SuccessExitStatus=143
User=tomcat
Group=tomcat

[Install]
WantedBy=multi-user.target

_EOT_
chmod 644 /usr/lib/systemd/system/tomcat9@.service

echo "Done."
exit 0
