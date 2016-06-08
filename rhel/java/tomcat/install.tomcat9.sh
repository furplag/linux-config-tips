#!/bin/bash

grep -e "^tomcat" /etc/passwd || useradd -u 91 tomcat -U -s /sbin/nologin

curl -fjkLO http://www-us.apache.org/dist/tomcat/tomcat-9/v9.0.0.M6/bin/apache-tomcat-9.0.0.M6.tar.gz

tar xf apache-tomcat-9.0.0.M6.tar.gz -C /usr/share
mv /usr/share/apache-tomcat-9.0.0.M6 /usr/share/tomcat9

mkdir -p /usr/share/tomcat9/conf/Catalina/localhost
chown tomcat:tomcat -R /usr/share/tomcat9
chmod 775 -R /usr/share/tomcat9
rm -rf /usr/share/tomcat9/bin/*.bat
rm -rf /usr/share/tomcat9/{temp,work}
chown tomcat:root -R /usr/share/tomcat9/conf
chmod 664 -R /usr/share/tomcat9/conf
chmod 660 /usr/share/tomcat9/conf/tomcat-users.xml

mv /usr/share/tomcat9/conf /etc/tomcat9
ln -s /etc/tomcat9 /usr/share/tomcat9/conf
mv /usr/share/tomcat9/logs /var/log/tomcat9
ln -s /var/log/tomcat9 /usr/share/tomcat9/logs

mkdir -p /var/cache/tomcat9/{temp,work}
chown tomcat:tomcat -R /var/cache/tomcat9
chmod 770 -R /var/cache/tomcat9
ln -s /var/cache/tomcat9/temp /usr/share/tomcat9/temp
ln -s /var/cache/tomcat9/work /usr/share/tomcat9/work

mkdir -p /var/lib/tomcat9
mv /usr/share/tomcat9/webapps /var/lib/tomcat9/webapps
chown tomcat:tomcat /var/lib/tomcat9
chmod 775 -R /var/lib/tomcat9
ln -s /var/lib/tomcat9/webapps /usr/share/tomcat9/webapps

mkdir -p /var/lib/tomcats
chown tomcat:tomcat /var/lib/tomcats
chmod 775 /var/lib/tomcats

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
# For tomcat.service it's /etc/sysconfig/tomcat9, for
# tomcat@instance it's /etc/sysconfig/tomcat9@instance.

# This variable is used to figure out if config is loaded or not.
TOMCAT_CFG_LOADED="1"

# In new-style instances, if CATALINA_BASE isn't specified, it will
# be constructed by joining TOMCATS_BASE and NAME.
TOMCATS_BASE="/var/lib/tomcats/"

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

_EOT_
chown tomcat:tomcat /etc/tomcat9/tomcat9.conf
chmod 664 /etc/tomcat9/tomcat9.conf

cat <<_EOT_> /usr/lib/systemd/system/tomcat9.service
[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target

[Service]
Type=forking
EnvironmentFile=/etc/tomcat9/tomcat9.conf
Environment="NAME="
EnvironmentFile=-/etc/sysconfig/tomcat9
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
# 0. systemctl enable tomcat@name.service
# 1. create catalina.base directory structure in
#    /var/lib/tomcats/name
# 2. profit.

[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target

[Service]
Type=forking
EnvironmentFile=/etc/tomcat9/tomcat9.conf
Environment="NAME=%I"
EnvironmentFile=-/etc/sysconfig/tomcat9@%I
ExecStart=/usr/share/tomcat9/bin/startup.sh
ExecStop=/usr/share/tomcat9/bin/shutdown.sh
SuccessExitStatus=143
User=tomcat
Group=tomcat

[Install]
WantedBy=multi-user.target

_EOT_
chmod 644 /usr/lib/systemd/system/tomcat9@.service

yum install -y apr15u-devel gcc openssl-devel --enablerepo=ius,furplag.github.io

tar xf /usr/share/tomcat9/bin/tomcat-native.tar.gz -C /usr/local/src
cd /usr/local/src/tomcat-native-1.2.7-src/native/

./configure \
--prefix=/usr \
--libdir=/usr/lib64 \
--with-java-home=/usr/java/latest \
--with-apr=/usr/bin/apr15u-1-config \
--with-ssl=/usr/include/openssl && \
make && make install
