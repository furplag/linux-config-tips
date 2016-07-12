#!/bin/bash
set -ue -o pipefail
export LC_ALL=C
###
# tomcat.install.sh
# https://github.com/furplag/linux-config-tips
# Copyright 2016 furplag
# Licensed under MIT (https://github.com/furplag/linux-config-tips/blob/master/LICENSE)
# 
# Automatically setting up to use Tomcat.
#   1. Install Tomcat.
#   2. Install Tomcat Native.
#   3. Enable Tomcat run as daemon.
#   4. Set service tomcat.
#   5. Enable Tomcat Manager.
# Requirements
#   1. environment named "JAVA_HOME".
#   2. dependency packages to build Tomcat native: apr-devel, automake, gcc, jpackage-utils, openssl-devel.

## variables
declare -r name=`basename $0`
declare -r datetime=`date +"%Y%m%d%H%M%S"`
declare -r currentDir=`pwd`
declare -r workDir=/tmp/$name.$datetime

declare -r url_tomcat_src=http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.36/bin/apache-tomcat-8.0.36.tar.gz
#declare -r url_tomcat_src=http://archive.apache.org/dist/tomcat/tomcat-9/v9.0.0.M8/bin/apache-tomcat-9.0.0.M8.tar.gz
#declare -r url_tomcat_src=file:///root/apache-tomcat-8.0.36.tar.gz
declare -r tomcat_src=$(echo $url_tomcat_src | sed -e 's/^.*\///g')

declare -r owner=tomcat
declare -r gid=53
declare -r uid=53
declare -r verStr=$(echo $tomcat_src | sed -e 's/^[^0-9\.]*//' -e 's/\.[^0-9]*$//g')
declare -r ver=$(echo $verStr | sed -e 's/\..*$//g')
declare -r tomcat_home=/usr/share/tomcat$ver
declare -r tomcat_manager=tomcat
declare -r tomcat_manager_pw=tomcat

declare url=
declare source=
declare extracted=

declare -r JAVA_HOME=${JAVA_HOME:-$(echo $(readlink -e $(which java 2>/dev/null)) | sed -e 's/\/bin\/java$//')}
declare withAPR=
declare withSSL=
declare withSSLIgnoreVersion=

[ -z $JAVA_HOME ] && echo "  Lost Java, install JDK first." && exit 1
`service tomcat$ver version >/dev/null 2>&1` && echo "  tomcat$ver already exist." && exit 0
[ -d $tomcat_home ] && mv $tomcat_home $tomcat_home.saved.$datetime

if ! grep -e "^${owner}" /etc/group >/dev/null; then
  echo "  create group: ${owner} (${gid})."
  groupadd -g $gid $owner
fi

if ! grep -e "^${owner}" /etc/passwd >/dev/null; then
  echo "  create user: ${owner} (${uid})."
  useradd -u $uid $owner -g $owner -d /usr/share/tomcat -s /sbin/nologin
fi

[ -d $workDir ] || mkdir -p $workDir || exit 1

url=$url_tomcat_src
source=$tomcat_src

echo "  Downloading Tomcat ..."
curl -fjkL $url -o $workDir/$source

extracted=$(tar tf $workDir/$source | sed -n -e 1p | sed -e 's/\/.*//')
tar xf $workDir/$source -C $workDir
if [ ! -d $workDir/$extracted ]; then echo "  extract ${source} failed."; exit 1; fi
mv $workDir/$extracted $tomcat_home
if [ ! -d $tomcat_home ]; then echo "  set tomcat${ver} to ${path} failed."; exit 1; fi

echo "  install tomcat daemon ..."
echo "  check build dependencies ..."
# automake
if [ $(rpm -qa automake | wc -l) -lt 1 ]; then
  if ! yum install -y -q automake >/dev/null; then
    echo -e "  install package \"automake\" first."
    exit 1
  fi
fi
# gcc
if [ $(rpm -qa gcc | grep x86_64 | wc -l) -lt 1 ]; then
  if ! yum install -y -q gcc >/dev/null; then
    echo -e "  install package \"gcc\" first."
    exit 1
  fi
fi
source=$(ls $tomcat_home/bin | grep commons-daemon-native.*.tar.gz)
extracted=$(tar tf $tomcat_home/bin/$source | sed -n -e 1p | sed -e 's/\/.*//')
tar xf $tomcat_home/bin/$source -C $workDir
if [ ! -d $workDir/$extracted ]; then echo "  extract ${source} failed."; exit 1; fi
cd $workDir/$extracted/unix
./configure \
--prefix=/usr \
--libdir=/usr/lib64 \
--with-java=$JAVA_HOME 1>/dev/null 2>&1 && \
make 1>/dev/null 2>&1

cd "${currentDir}"
if [ ! -e $workDir/$extracted/unix/jsvc ]; then echo "  extract ${source} failed."; exit 1; fi
mv $workDir/$extracted/unix/jsvc $tomcat_home/bin/jsvc
if [ ! -e $tomcat_home/bin/jsvc ]; then echo "  set tomcat-daemon failed."; exit 1; fi

# Install Tomcat native (source included).
if ! ls /usr/lib64 | grep tcnative >/dev/null; then
  echo "  install tomcat native ..."
  echo "  check build dependencies ..."
  # apr-devel
  if [ $(rpm -qa apr*-devel | grep x86_64 | wc -l) -lt 1 ]; then
    if yum repolist --disableplugin=* --disablerepo=* --enablerepo=ius 1>/dev/null 2>&1; then
      if yum install -y -q apr15u-devel --enablerepo=ius >/dev/null; then withAPR=/usr/bin/apr15u-1-config; fi   
    elif yum install -y -q apr-devel >/dev/null; then
      withAPR=/usr/bin/apr-1-config
    fi
  elif [ $(rpm -qa apr15u-devel | grep x86_64 | wc -l) -gt 0 ]; then
    withAPR=/usr/bin/apr15u-1-config
  elif [ $(rpm -qa apr-devel | grep x86_64 | wc -l) -gt 0 ]; then
    withAPR=/usr/bin/apr-1-config
  fi
  [ -z $withAPR ] && echo -e "  install package \"apr-devel\" first." && exit 1

  # openssl-devel
  if [ $(rpm -qa openssl-devel | grep x86_64 | wc -l) -lt 1 ]; then
    if yum repolist --disableplugin=* --disablerepo=* --enablerepo=furplag.github.io 1>/dev/null 2>&1; then
      yum install -y -q openssl-devel --enablerepo=furplag.github.io >/dev/null
    fi
    [ $(rpm -qa openssl-devel | grep x86_64 | wc -l) -lt 1 ] && yum install -y -q openssl-devel >/dev/null
  fi
  [ $(rpm -qa openssl-devel | grep x86_64 | wc -l) -lt 1 ] && echo -e "  install package \"openssl-devel\" first." && exit 1

  source=$(ls $tomcat_home/bin | grep tomcat-native.*.tar.gz)
  extracted=$(tar tf $tomcat_home/bin/$source | sed -n -e 1p | sed -e 's/\/.*//')
  tar xf $tomcat_home/bin/$source -C $workDir
  if [ ! -d $workDir/$extracted ]; then echo "  extract ${source} failed."; exit 1; fi
  cd $workDir/$extracted/native

  openssl_version=$(openssl version | cut -d ' ' -f 2)
  if [ $($openssl_version | cut -d '.' -f 1) -lt 1 ]; then
    echo "  too old OpenSSL, update first"
    exit 1
  elif [ $($openssl_version | cut -d '.' -f 3 | sed -e ) -lt 2 ]; then
    withSSL="yes"
    withSSLIgnoreVersion="--disable-openssl-version-check"
  else
    withSSL="/usr/include/openssl"
  fi

  ./configure \
  --prefix=/usr \
  --libdir=/usr/lib64 \
  --with-java-home=$JAVA_HOME \
  --with-apr=$withAPR \
  --with-ssl=$withSSL "${withSSLIgnoreVersion}" 1>/dev/null 2>&1 && \
  make 1>/dev/null 2>&1 && \
  make install 1>/dev/null 2>&1
  cd "${currentDir}"
  if ! ls /usr/lib64 | grep tcnative >/dev/null; then echo "  install ${source} failed."; exit 1; fi
fi

echo "  building structure ..."
mkdir -p $tomcat_home/conf/Catalina/localhost
chown root:$owner -R $tomcat_home
chmod 0775 -R $tomcat_home
rm -rf $tomcat_home/{logs,temp,work}

# bin
rm -rf $tomcat_home/bin/*.bat
chmod 0664 $tomcat_home/bin/*.*
chmod +x $tomcat_home/bin/{jsvc,*.sh}

# conf
[ -d /etc/tomcat$ver ] && mv /etc/tomcat$ver /etc/tomcat$ver.$datetime
mv $tomcat_home/conf /etc/tomcat$ver
ln -s /etc/tomcat$ver $tomcat_home/conf
chown $owner:$owner /etc/tomcat$ver/*.*
chmod 0664 /etc/tomcat$ver/*.*
chmod 0660 /etc/tomcat$ver/tomcat-users.xml

# logs
[ -d /var/log/tomcat$ver ] && mv /var/log/tomcat$ver /var/log/tomcat$ver.$datetime
mkdir -p /var/log/tomcat$ver
chown tomcat:tomcat /var/log/tomcat$ver
chmod 0770 /var/log/tomcat$ver
ln -s /var/log/tomcat$ver $tomcat_home/logs

# temp, work
[ -d /var/cache/tomcat$ver ] && mv /var/cache/tomcat$ver /var/cache/tomcat$ver.$datetime
mkdir -p /var/cache/tomcat$ver/{temp,work}
chown $owner:$owner -R /var/cache/tomcat$ver
chmod 0770 -R /var/cache/tomcat$ver
ln -s /var/cache/tomcat$ver/temp $tomcat_home/temp
ln -s /var/cache/tomcat$ver/work $tomcat_home/work

# webapps
[ -d /var/lib/tomcat$ver ] && mv /var/lib/tomcat$ver /var/lib/tomcat$ver.$datetime
mkdir -p /var/lib/tomcat$ver
mv $tomcat_home/webapps /var/lib/tomcat$ver/webapps
chown $owner:$owner -R /var/lib/tomcat$ver
chmod 0770 /var/lib/tomcat$ver
chmod 0775 -R /var/lib/tomcat$ver/webapps
ln -s /var/lib/tomcat$ver/webapps $tomcat_home/webapps

# pid(s)
[ -d /var/run/tomcat ] && mv /var/run/tomcat /var/run/tomcat.$datetime
mkdir -p /var/run/tomcat
chown $owner:$owner /var/run/tomcat
chmod 0775 /var/run/tomcat
ln -s /var/run/tomcat $tomcat_home/run

# manager GUI
[ -n $tomcat_manager ] && \
sed -i -e 's/<\/tomcat-users[^>]*>/<!-- \0 -->/' $tomcat_home/conf/tomcat-users.xml && \
cat <<_EOT_>> $tomcat_home/conf/tomcat-users.xml
  <role rolename="admin-gui" />
  <role rolename="admin-script" />
  <role rolename="manager-gui" />
  <role rolename="manager-jmx" />
  <role rolename="manager-script" />
  <role rolename="manager-status" />
  <user username="${tomcat_manager}" password="${tomcat_manager_pw}" roles="admin-gui,admin-script,manager-gui,manager-jmx,manager-script,manager-status" />
</tomcat-users>

_EOT_

echo "  Setting up ..."
# environments
cat <<_EOT_> /etc/sysconfig/tomcat$ver
# Service-specific configuration file for tomcat. This will be sourced by
# the SysV init script after the global configuration file
# /etc/tomcat$ver/tomcat$ver.conf, thus allowing values to be overridden in
# a per-service manner.
#
# NEVER change the init script itself. To change values for all services make
# your changes in /etc/tomcat$ver/tomcat$ver.conf
#
# To change values for a specific service make your edits here.
# To create a new service create a link from /etc/init.d/<your new service> to
# /etc/init.d/tomcat$ver (do not copy the init script) and make a copy of the
# /etc/sysconfig/tomcat$ver file to /etc/sysconfig/<your new service> and change
# the property values so the two services won't conflict. Register the new
# service in the system as usual (see chkconfig and similars).
#

# Where your java installation lives
#JAVA_HOME="/usr/lib/jvm/java"

# Where your tomcat installation lives
#CATALINA_BASE="${tomcat_home}"
#CATALINA_HOME="${tomcat_home}"
#JASPER_HOME="${tomcat_home}"
#CATALINA_TMPDIR="/var/cache/tomcat${ver}/temp"

# You can pass some parameters to java here if you wish to
#JAVA_OPTS="-Xminf0.1 -Xmaxf0.3"

# Use JAVA_OPTS to set java.library.path for libtcnative.so
#JAVA_OPTS="-Djava.library.path=/usr/lib64"

# What user should run tomcat
#TOMCAT_USER="${owner}"

# You can change your tomcat locale here
#LANG="en_US"

# Run tomcat under the Java Security Manager
#SECURITY_MANAGER="false"

# Time to wait in seconds, before killing process
#SHUTDOWN_WAIT="30"

# Whether to annoy the user with "attempting to shut down" messages or not
#SHUTDOWN_VERBOSE="false"

# Set the TOMCAT_PID location
#CATALINA_PID="/var/run/tomcat8.pid"

# Connector port is 8080 for this tomcat instance
#CONNECTOR_PORT="8080"

# If you wish to further customize your tomcat environment,
# put your own definitions here
# (i.e. LD_LIBRARY_PATH for some jdbc drivers)

_EOT_
chown root:$owner /etc/sysconfig/tomcat$ver
chmod 0644 /etc/sysconfig/tomcat$ver

cat <<_EOT_> $tomcat_home/conf/tomcat$ver.conf
# System-wide configuration file for tomcat services
# This will be loaded by systemd as an environment file,
# so please keep the syntax.
#
# There are 2 "classes" of startup behavior in this package.
# The old one, the default service named tomcat.service.
# The new named instances are called tomcat$ver@instance.service.
#
# Use this file to change default values for all services.
# Change the service specific ones to affect only one service.
# For tomcat8.service it's /etc/sysconfig/tomcat$ver, for
# tomcat$ver@instance it's /etc/sysconfig/tomcat$ver@instance.

# In new-style instances, if CATALINA_BASE isn't specified, it will
# be constructed by joining TOMCATS_BASE and NAME.
TOMCATS_BASE="${tomcat_home}/instances/"

# Where your java installation lives
JAVA_HOME="${JAVA_HOME}"

# Where your tomcat installation lives
CATALINA_HOME="${tomcat_home}"

# System-wide tmp
CATALINA_TMPDIR="${tomcat_home}/temp"

# You can change your tomcat locale here
LANG="${LANG}"

# Run tomcat under the Java Security Manager
SECURITY_MANAGER="false"

# Time to wait in seconds, before killing process
# TODO(stingray): does nothing, fix.
# SHUTDOWN_WAIT="30"

# Whether to annoy the user with "attempting to shut down" messages or not
SHUTDOWN_VERBOSE="true"

# Set the TOMCAT_PID location
CATALINA_PID="${tomcat_home}/run/tomcat${ver}.pid"

# Connector port is 8080 for this tomcat instance
#CONNECTOR_PORT="8080"

# If you wish to further customize your tomcat environment,
# put your own definitions here
# (i.e. LD_LIBRARY_PATH for some jdbc drivers)
CATALINA_OPTS="-server -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true -Dfile.encoding=utf-8"
CATALINA_OPTS="-Xms512m -Xmx1g -XX:PermSize=256m -XX:MaxPermSize=1g -XX:NewSize=128m"
CATALINA_OPTS="-Xloggc:${tomcat_home}/logs/gc.log -XX:+PrintGCDetails"
CATALINA_OPTS="-Djava.security.egd=file:/dev/./urandom"

_EOT_
[ $((echo "`java -version 2>&1`") | grep "java version" | cut -d "\"" -f 2 | cut -d "." -f 2) -gt 7 ] && \
sed -i -e 's/PermSize/MetaspaceSize/g' $tomcat_home/conf/tomcat$ver.conf
chown $owner:$owner $tomcat_home/conf/tomcat$ver.conf
chmod 0664 $tomcat_home/conf/tomcat$ver.conf

cat <<_EOF_> /etc/rc.d/init.d/tomcat$ver
#!/bin/bash
#
# tomcat       start and stop tomcat
# chkconfig: - 80 20
#
### BEGIN INIT INFO
# Provides: tomcat
# Required-Start: \$network \$syslog
# Required-Stop: \$network \$syslog
# Default-Start: 2 3 4 5
# Default-Stop: 1 6
# Description: Release implementation for Servlet 3.0 and JSP 2.2
# Short-Description: start and stop tomcat
### END INIT INFO

## load functions.
. /etc/rc.d/init.d/functions
NAME="\$(basename \$0)"

unset ISBOOT
if [ "\${NAME:0:1}" = "S" -o "\${NAME:0:1}" = "K" ]; then
  NAME="\${NAME:3}"
  ISBOOT="1"
fi

# For SELinux we need to use 'runuser' not 'su'
if [ -x "/sbin/runuser" ]; then
  SU="/sbin/runuser -s /bin/sh"
else
  SU="/bin/su -s /bin/sh"
fi

# load default config.
[ -r "/etc/sysconfig/\${NAME}" ] && . /etc/sysconfig/\${NAME}

# load tomcat config.
TOMCAT_CFG="/etc/tomcat${ver}/tomcat${ver}.conf"
[ -r "\$TOMCAT_CFG" ] && . \$TOMCAT_CFG

# Define Settings.
## connector port is "connector.port" in conf/catalina.properties
#CONNECTOR_PORT="\${CONNECTOR_PORT:-8080}"
TOMCAT_PROG="\${NAME}"
TOMCAT_USER="\${TOMCAT_USER:-${owner}}"
CATALINA_HOME="\${CATALINA_HOME:-\${CATALINA_BASE=-${tomcat_home}}}"
TOMCAT_LOG="\${TOMCAT_LOG:-\${CATALINA_HOME}/logs/\${NAME}-initd.log}"
SHUTDOWN_WAIT="\${SHUTDOWN_WAIT:-\${KILL_SLEEP_WAIT:-5}}"
KILL_SLEEP_WAIT="\${KILL_SLEEP_WAIT:-\${SHUTDOWN_WAIT}}"
CATALINA_PID="\${CATALINA_PID:-/var/run/\${NAME}.pid}"
JAVA_OPTS="\$(grep -E "^JAVA_OPTS=" \$TOMCAT_CFG | sed -e 's/JAVA_OPTS=\"/ /' | sed -e 's/\"\$//')"
CATALINA_OPTS="\$(echo "\$(grep -E "^CATALINA_OPTS=" \$TOMCAT_CFG | sed -e 's/CATALINA_OPTS=\"/ /' | sed -e 's/\"\$//')")"
RETVAL="0"

# See how we were called.
function start() {
  echo -n "Starting \${TOMCAT_PROG}: "
  if [ "\$RETVAL" != "0" ]; then 
   failure
   return
  fi
  if [ -f "/var/lock/subsys/\${NAME}" ]; then
    if [ -s "\${CATALINA_PID}" ]; then
      read kpid < \$CATALINA_PID
      [ -d "/proc/\${kpid}" ] && success && return 0
    fi
  fi

  # fix permissions on the log and pid files
  touch \$CATALINA_PID 2>&1 || RETVAL="4"
  [ "\$RETVAL" -eq "0" -a "\$?" -eq "0" ] && chown \${TOMCAT_USER}:\${TOMCAT_USER} \$CATALINA_PID
  [ "\$RETVAL" -eq "0" ] && touch \$TOMCAT_LOG 2>&1 || RETVAL="4" 
  [ "\$RETVAL" -eq "0" -a "\$?" -eq "0" ] && chown \${TOMCAT_USER}:\${TOMCAT_USER} \$TOMCAT_LOG

  cat <<_EOT_> \$CATALINA_HOME/bin/setenv.sh
CATALINA_PID="\${CATALINA_PID}"
JAVA_OPTS="\${JAVA_OPTS}"
CATALINA_OPTS="\$(echo "\${CATALINA_OPTS}")"

_EOT_
  chown \$TOMCAT_USER:\$TOMCAT_USER \$CATALINA_HOME/bin/setenv.sh
  chmod 0644 \$CATALINA_HOME/bin/setenv.sh

  if [ "\$RETVAL" -eq "0" -a "\$SECURITY_MANAGER" = "true" ]; then
    \$SU - \$TOMCAT_USER -c "\${CATALINA_HOME}/bin/startup.sh -security" >> \${TOMCAT_LOG} 2>&1 || RETVAL="4"
  else
    [ "\$RETVAL" -eq "0" ] && \$SU - \$TOMCAT_USER -c "\${CATALINA_HOME}/bin/startup.sh" >> \${TOMCAT_LOG} 2>&1 || RETVAL="4"
  fi
  if [ "\$RETVAL" -eq "0" ]; then 
    touch /var/lock/subsys/\${NAME}
    success
  else
    echo -n "Error code \${RETVAL}"
    failure
  fi
  rm -f \$CATALINA_HOME/bin/setenv.sh
}

function stop() {
  #check to see if pid file is good. We only want to stop tomcat8 if 
  #we started it from this init script
  running_pid=\$(pgrep -f "org.apache.catalina.startup.Bootstrap start")
  if [ -f \$CATALINA_PID ]; then
    read kpid junk< \$CATALINA_PID
    if [ -z "\${kpid}" ]; then
      echo -n "PID file empty"
      rm -f /var/lock/subsys/\${NAME} \$CATALINA_PID
      failure
      exit 4 
    fi
    if [ -z "\$running_pid" ]; then
      echo -n "no \${NAME} running, but pid file exists - cleaning up"
      rm -f /var/lock/subsys/\${NAME} \$CATALINA_PID
      success
      exit 0
    fi
    if [ -z "\$(echo \${kpid} | fgrep -x "\${running_pid}")" ]; then
      echo -n "PID file does not match pid of any running \${NAME}"
      failure
      rm -f /var/lock/subsys/\${NAME} \$CATALINA_PID
      exit 4
    fi

    cat <<_EOT_> \$CATALINA_HOME/bin/setenv.sh
CATALINA_PID="\${CATALINA_PID}"
JAVA_OPTS="\${JAVA_OPTS}"

_EOT_
    chown \$TOMCAT_USER:\$TOMCAT_USER \$CATALINA_HOME/bin/setenv.sh
    chmod 0644 \$CATALINA_HOME/bin/setenv.sh

    #stop tomcat
    echo -n "Stopping \${TOMCAT_PROG}: "

    \$SU - \$TOMCAT_USER -c "\${CATALINA_HOME}/bin/shutdown.sh" >> \${TOMCAT_LOG} 2>&1 || RETVAL="4"
    if [ "\$RETVAL" -eq "4" ]; then
      sleep 1
      if [ "\$SHUTDOWN_VERBOSE" = "true" ]; then
          echo "Failed to stop \${NAME} normally, sending a graceful kill."
      fi
      kill \$kpid > /dev/null 2>&1
      sleep 1
    fi

    #wait for tomcat to really shutdown
    count=0
    until [ "\$(ps --pid \$kpid | grep -c \$kpid)" -eq "0" ] || [ "\$count" -gt "\$SHUTDOWN_WAIT" ]; do
      if [ "\$SHUTDOWN_VERBOSE" = "true" ]; then
        if [ "\$count" -gt 1 ];then
          echo -n "waiting for processes \${NAME} (\$kpid) to exit"
        else
          echo -n "."
        fi
      fi
      sleep 1
      let count="\${count}+1"
    done

    if [ "\$count" -gt "\$SHUTDOWN_WAIT" ]; then
      if [ "\${SHUTDOWN_VERBOSE}" = "true" ]; then
        echo -n "Failed to stop \${NAME} (\$kpid) gracefully after \$SHUTDOWN_WAIT seconds, sending SIGKILL."
      fi
      kill -9 \$kpid
      if [ "\$SHUTDOWN_VERBOSE" = "true" ]; then
        echo "Waiting for \${NAME} (\$kpid) to exit."
      fi
      count=0
      until [ "\$(ps --pid \$kpid | grep -c \$kpid)" -eq "0" ] || [ "\$count" -gt "\$SHUTDOWN_WAIT" ]; do
        if [ "\$SHUTDOWN_VERBOSE" = "true" ]; then
          echo "waiting for \${NAME} (\$kpid) to exit. It could be in the UNINTERRUPTIBLE state"
        fi
        sleep 1
        let count="\${count}+1"
      done
      warning
    fi
    #check to make sure tomcat is gone
    if [ "\$(ps --pid \$kpid | grep -c \$kpid)" -eq "0" ]; then
      rm -f /var/lock/subsys/\${NAME} \$CATALINA_PID
      RETVAL="0"
      success
    else
      echo -n "Unable to stop \${NAME} (\$kpid)"
      RETVAL="4"
      failure
    fi
  elif [ -n "\$running_pid" ]; then
    echo -n "\${NAME} running, but no pid file"
    failure
    RETVAL="4"
  else
    success
  fi

  rm -f \$CATALINA_HOME/bin/setenv.sh
  return \$RETVAL
}

function configtest() {
  cat <<_EOT_> \$CATALINA_HOME/bin/setenv.sh
CATALINA_PID="\${CATALINA_PID}"
JAVA_OPTS="\${JAVA_OPTS}"
CATALINA_OPTS="\$(echo "\${CATALINA_OPTS}")"

_EOT_
  chown \$TOMCAT_USER:\$TOMCAT_USER \$CATALINA_HOME/bin/setenv.sh
  chmod 0644 \$CATALINA_HOME/bin/setenv.sh

  \$SU - \$TOMCAT_USER -c "\${CATALINA_HOME}/bin/catalina.sh configtest" 1>/dev/null

  rm -f \$CATALINA_HOME/bin/setenv.sh
}

function version() {
  \$SU - \$TOMCAT_USER -c "\${CATALINA_HOME}/bin/version.sh" 2>&1
}

function usage() {
   echo "Usage: \$0 {start|stop|restart|status|version|configtest}"
   RETVAL="2"
}

function rh_status() {
    status -p \$CATALINA_PID \${NAME}
}

function rh_status_q() {
    rh_status >/dev/null 2>&1
}

# See how we were called.
RETVAL="0"
case "\$1" in
  start)
    rh_status_q && exit 0
    start
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    start
    ;;
  status)
    if [ -s "\${CATALINA_PID}" ]; then
      read kpid junk < \$CATALINA_PID
      if [ -d "/proc/\${kpid}" ]; then
        echo -n "\${NAME} (pid \${kpid}) is running..."
        success
        RETVAL="0"
      else
        # The pid file exists but the process is not running
        echo -n "PID file exists, but process is not running"
        warning
        RETVAL="1"
      fi
    else
      pid="\$(/usr/bin/pgrep -d , -u \${TOMCAT_USER} -G \${TOMCAT_USER} java)"
      if [ -z "\$pid" ]; then
        echo "\${NAME} is stopped"
        success
        RETVAL="3"
      else
        echo "\${NAME} (pid \$pid) is running, but PID file is missing"
        success
        RETVAL="0"
      fi
    fi
    ;;
  version)
    version
    ;;
  configtest)
    if rh_status; then
      echo -e "\"service \${NAME} stop\" first."
      warning
      exit 1
    fi
    configtest
    ;;
  *)
    usage
    ;;
esac

exit \$RETVAL

_EOF_
chmod 0755 /etc/rc.d/init.d/tomcat$ver

sed -i -e "s/Server port=\"8005\"/Server port=\"\${server.port.shutdown}\"/g" \
-e "s/Connector port=\"8080\"/Connector port=\"\${connector.port}\"/g" \
-e "s/Connector port=\"8009\"/Connector port=\"\${connector.port.ajp}\"/g" \
-e "s/redirectPort=\"8443\"/redirectPort=\"\${connector.port.redirect}\"/g" \
-e "s/Connector port=\"8443\"/Connector port=\"\${connector.port.ssl}\"/g" \
$tomcat_home/conf/server.xml

cat <<_EOT_>> $tomcat_home/conf/catalina.properties

# Customized properties for server.xml
server.port.shutdown=8005
connector.port=8080
connector.port.ajp=8009
connector.port.redirect=8443
connector.port.ssl=8443

_EOT_

if [ -r /etc/httpd/conf.d/ssl.conf ]; then
  echo "  Setting SSL ..."
  sslCert=$(grep -E "^[^\#]+SSLCertificateFile " /etc/httpd/conf.d/ssl.conf | sed -n -e 1p | sed -e 's/^.*SSLCertificateFile //')
  sslKey=$(grep -E "^[^\#]+SSLCertificateKeyFile " /etc/httpd/conf.d/ssl.conf | sed -n -e 1p | sed -e 's/^.*SSLCertificateKeyFile //')
  
  if [ -e $sslCert ] && [ -e $sslKey ]; then
  sed -i -e 's/<Engine name="Catalina" defaultHost="localhost">/<Engine name="Catalina" jvmRoute="origin" defaultHost="localhost">/' \
  -e 's/<\/Service>/<\!-- \n\0/' \
  -e 's/<\/Server>/\0\n -->/' \
  $tomcat_home/conf/server.xml

  cat <<_EOT_>> $tomcat_home/conf/server.xml
<!-- Define a SSL Coyote HTTP/1.1 Connector on port 8443 -->
<Connector
  protocol="org.apache.coyote.http11.Http11AprProtocol"
  port="\${connector.port.ssl}" maxThreads="200"
  scheme="https" secure="true" SSLEnabled="true"
  SSLCertificateFile="${sslCert}"
  SSLCertificateKeyFile="${sslKey}"
  SSLProtocol="TLSv1+TLSv1.1+TLSv1.2"/>

</Service>
</Server>

_EOT_
  fi
fi

echo "  Testing ..."
if ! systemctl start tomcat$ver 1>/dev/null 2>&1; then
  echo "  install tomcat${ver} failed."
  exit 1
fi
if ! systemctl status tomcat$ver 1>/dev/null 2>&1; then
  echo "  install tomcat${ver} failed."
  exit 1
fi
if ! systemctl stop tomcat$ver 1>/dev/null 2>&1; then
  echo "  install tomcat${ver} failed."
  exit 1
fi

echo "Cleanup ..."
rm -rf $workDir

echo "Done."
exit 0
