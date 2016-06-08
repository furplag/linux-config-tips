#!/bin/bash

grep -e "^tomcat" /etc/passwd || useradd -u 91 tomcat -U -s /sbin/nologin

curl -fjkLO http://ftp.meisei-u.ac.jp/mirror/apache/dist/tomcat/tomcat-8/v8.0.35/bin/apache-tomcat-8.0.35.tar.gz

tar xf apache-tomcat-8.0.35.tar.gz -C /usr/share
mv /usr/share/apache-tomcat-8.0.35 /usr/share/tomcat8

mkdir -p /usr/share/tomcat8/conf/Catalina/localhost
chown tomcat:tomcat -R /usr/share/tomcat8
chmod 775 -R /usr/share/tomcat8
rm -rf /usr/share/tomcat8/bin/*.bat
rm -rf /usr/share/tomcat8/{temp,work}
chown tomcat:root -R /usr/share/tomcat8/conf
chmod 664 -R /usr/share/tomcat8/conf
chmod 660 /usr/share/tomcat8/conf/tomcat-users.xml

mv /usr/share/tomcat8/conf /etc/tomcat8
ln -s /etc/tomcat8 /usr/share/tomcat8/conf
mv /usr/share/tomcat8/logs /var/log/tomcat8
ln -s /var/log/tomcat8 /usr/share/tomcat8/logs

mkdir -p /var/cache/tomcat8/{temp,work}
chown tomcat:tomcat -R /var/cache/tomcat8
chmod 770 -R /var/cache/tomcat8
ln -s /var/cache/tomcat8/temp /usr/share/tomcat8/temp
ln -s /var/cache/tomcat8/work /usr/share/tomcat8/work

mkdir -p /var/lib/tomcat8
mv /usr/share/tomcat8/webapps /var/lib/tomcat8/webapps
chown tomcat:tomcat /var/lib/tomcat8
chmod 775 -R /var/lib/tomcat8
ln -s /var/lib/tomcat8/webapps /usr/share/tomcat8/webapps

mkdir -p /var/lib/tomcat8s
chown tomcat:tomcat /var/lib/tomcat8s
chmod 775 /var/lib/tomcat8s

touch /var/run/tomcat8.pid
chown tomcat:tomcat /var/run/tomcat8.pid
chmod 664 /var/run/tomcat8.pid

# ---
exit 0
# ---

sed -i -e 's/Context antiResourceLocking="false"/Context antiResourceLocking="true"/' -e 's/<Context[^>]*>$/\0\n<!-- /' -e 's/<\/Context/ -->\n\0/' /usr/share/tomcat8/webapps/{host-manager,manager}/META-INF/context.xml
sed -i -e 's/<\/tomcat-users[^>]*>/<!-- \0 -->/' /usr/share/tomcat8/conf/tomcat-users.xml
cat <<_EOT_>> /usr/share/tomcat8/conf/tomcat-users.xml
  <role rolename="admin-gui" />
  <role rolename="admin-script" />
  <role rolename="manager-gui" />
  <role rolename="manager-jmx" />
  <role rolename="manager-script" />
  <role rolename="manager-status" />
  <user username="tomcat" password="tomcat" roles="admin-gui,manager-gui" />
</tomcat-users>

_EOT_


cat <<_EOT_> /etc/sysconfig/tomcat8
# Service-specific configuration file for tomcat. This will be sourced by
# the SysV init script after the global configuration file
# /etc/tomcat8/tomcat8.conf, thus allowing values to be overridden in
# a per-service manner.
#
# NEVER change the init script itself. To change values for all services make
# your changes in /etc/tomcat8/tomcat8.conf
#
# To change values for a specific service make your edits here.
# To create a new service create a link from /etc/init.d/<your new service> to
# /etc/init.d/tomcat8 (do not copy the init script) and make a copy of the
# /etc/sysconfig/tomcat8 file to /etc/sysconfig/<your new service> and change
# the property values so the two services won't conflict. Register the new
# service in the system as usual (see chkconfig and similars).
#

# Where your java installation lives
#JAVA_HOME="/usr/lib/jvm/java"

# Where your tomcat installation lives
#CATALINA_BASE="/usr/share/tomcat8"
#CATALINA_HOME="/usr/share/tomcat8"
#JASPER_HOME="/usr/share/tomcat8"
#CATALINA_TMPDIR="/var/cache/tomcat8/temp"

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
chown root:tomcat /etc/sysconfig/tomcat8
chmod 644 /etc/sysconfig/tomcat8

cat <<_EOT_> /etc/tomcat8/tomcat8.conf
# System-wide configuration file for tomcat services
# This will be loaded by systemd as an environment file,
# so please keep the syntax.
#
# There are 2 "classes" of startup behavior in this package.
# The old one, the default service named tomcat.service.
# The new named instances are called tomcat8@instance.service.
#
# Use this file to change default values for all services.
# Change the service specific ones to affect only one service.
# For tomcat8.service it's /etc/sysconfig/tomcat8, for
# tomcat8@instance it's /etc/sysconfig/tomcat8@instance.

# This variable is used to figure out if config is loaded or not.
TOMCAT_CFG_LOADED="1"

# In new-style instances, if CATALINA_BASE isn't specified, it will
# be constructed by joining TOMCATS_BASE and NAME.
TOMCATS_BASE="/var/lib/tomcats/"

# Where your java installation lives
JAVA_HOME="${JAVA_HOME}"

# Where your tomcat installation lives
CATALINA_HOME="/usr/share/tomcat8"

# System-wide tmp
CATALINA_TMPDIR="/var/cache/tomcat8/temp"

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

_EOT_
chown tomcat:tomcat /etc/tomcat8/tomcat8.conf
chmod 664 /etc/tomcat8/tomcat8.conf

cat <<_EOT_> /usr/lib/systemd/system/tomcat8.service
[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target

[Service]
Type=forking
EnvironmentFile=/etc/tomcat8/tomcat8.conf
Environment="NAME="
EnvironmentFile=-/etc/sysconfig/tomcat8
ExecStart=/usr/share/tomcat8/bin/startup.sh
ExecStop=/usr/share/tomcat8/bin/shutdown.sh
SuccessExitStatus=143
User=tomcat
Group=tomcat

[Install]
WantedBy=multi-user.target

_EOT_
chmod 644 /usr/lib/systemd/system/tomcat8.service

cat <<_EOT_> /usr/lib/systemd/system/tomcat8@.service
# Systemd unit file for tomcat instances.
# 
# To create clones of this service:
# 0. systemctl enable tomcat8@name.service
# 1. create catalina.base directory structure in
#    /var/lib/tomcat8s/name
# 2. profit.

[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target

[Service]
Type=forking
EnvironmentFile=/etc/tomcat8/tomcat8.conf
Environment="NAME=%I"
EnvironmentFile=-/etc/sysconfig/tomcat8@%I
ExecStart=/usr/share/tomcat8/bin/startup.sh
ExecStop=/usr/share/tomcat8/bin/shutdown.sh
SuccessExitStatus=143
User=tomcat
Group=tomcat

[Install]
WantedBy=multi-user.target

_EOT_
chmod 644 /usr/lib/systemd/system/tomcat8@.service

yum install -y apr15u-devel gcc openssl-devel --enablerepo=ius,furplag.github.io

exit 0

tar xf /usr/share/tomcat9/bin/tomcat-native.tar.gz -C /usr/local/src
cd /usr/local/src/tomcat-native-1.2.7-src/native/

./configure \
--prefix=/usr \
--libdir=/usr/lib64 \
--with-java-home=/usr/java/latest \
--with-apr=/usr/bin/apr15u-1-config \
--with-ssl=/usr/include/openssl && \
make && make install
