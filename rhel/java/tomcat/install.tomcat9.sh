#!/bin/bash

useradd -u 91 tomcat -U -r -s /sbin/nologin

curl -fjkLO http://www-us.apache.org/dist/tomcat/tomcat-9/v9.0.0.M6/bin/apache-tomcat-9.0.0.M6.tar.gz

tar xf apache-tomcat-9.0.0.M6.tar.gz -C /usr/share
mv /usr/share/apache-tomcat-9.0.0.M6 /usr/share/tomcat9

chown root:tomcat -R /usr/share/tomcat9/
chmod 775 /usr/share/tomcat9/

chown tomcat:tomcat /usr/share/tomcat9/bin
chown tomcat:tomcat /usr/share/tomcat9/bin/*
rm -rf /usr/share/tomcat9/bin/*.bat

chown tomcat:tomcat /usr/share/tomcat9/lib
chown tomcat:tomcat /usr/share/tomcat9/lib/*

chown root:tomcat -R /usr/share/tomcat9/conf
chmod 755 /usr/share/tomcat9/conf
mv /usr/share/tomcat9/conf /etc/tomcat9
ln -s /etc/tomcat9 /usr/share/tomcat9/conf
chown tomcat:root -R /etc/tomcat9/*
chmod 664 /etc/tomcat9/*
chmod 660 /etc/tomcat9/tomcat-users.xml

mkdir -p /etc/tomcat9/Catalina/localhost
chown root:tomcat /etc/tomcat9/Catalina
chown root:tomcat /etc/tomcat9/Catalina/localhost
chmod 775 /etc/tomcat9/Catalina
chmod 775 /etc/tomcat9/Catalina/localhost

chown root:tomcat -R /usr/share/tomcat9/{logs,temp,work}
chmod 770 /usr/share/tomcat9/{logs,temp,work}
mv /usr/share/tomcat9/logs /var/log/tomcat9
ln -s /var/log/tomcat9 /usr/share/tomcat9/logs

mkdir /var/cache/tomcat9
chown root:tomcat -R /var/cache/tomcat9/
chmod 770 /var/cache/tomcat9
mv /usr/share/tomcat9/temp /var/cache/tomcat9/temp
mv /usr/share/tomcat9/work /var/cache/tomcat9/work
ln -s /var/cache/tomcat9/temp /usr/share/tomcat9/temp
ln -s /var/cache/tomcat9/work /usr/share/tomcat9/work

mkdir /var/lib/tomcat9
chown root:tomcat /var/lib/tomcat9
chmod 775 /var/lib/tomcat9

mv /usr/share/tomcat9/temp /var/cache/tomcat9/temp
ln -s /var/cache/tomcat9/temp /usr/share/tomcat9/temp
mv /usr/share/tomcat9/work /var/cache/tomcat9/work
ln -s /var/cache/tomcat9/work /usr/share/tomcat9/work

mkdir /var/lib/tomcat9
chown root:tomcat /var/lib/tomcat9
chmod 755 /var/lib/tomcat9

chown root:tomcat /usr/share/tomcat9/webapps
chmod 775 /usr/share/tomcat9/webapps
chown tomcat:tomcat -R /usr/share/tomcat9/webapps/*
mv /usr/share/tomcat9/webapps /var/lib/tomcat9/webapps
ln -s /var/lib/tomcat9/webapps /usr/share/tomcat9/webapps

mkdir /var/lib/tomcats
chown root:tomcat /var/lib/tomcats
chmod 755 /var/lib/tomcats

touch /var/run/tomcat9.pid
chown tomcat:tomcat /var/run/tomcat9.pid

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
EnvironmentFile=/etc/tomcat/tomcat9.conf
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
EnvironmentFile=/etc/tomcat/tomcat9.conf
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

