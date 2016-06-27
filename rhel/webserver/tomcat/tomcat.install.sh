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
#   4. Set tomcat8.service ( also enable @instance ) .
#   5. Enable Tomcat Manager.
# Requirements
#   1. environment named "JAVA_HOME".
#   2. dependency packages to build Tomcat native: apr-devel, automake, gcc, openssl-devel.

## variables
declare -r name=`basename $0`
declare -r datetime=`date +"%Y%m%d%H%M%S"`
declare -r currentDir=`pwd`
declare -r workDir=/tmp/$name.$datetime

declare -r url_tomcat_src=http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.35/bin/apache-tomcat-8.0.35.tar.gz
#declare -r url_tomcat_src=http://archive.apache.org/dist/tomcat/tomcat-9/v9.0.0.M8/bin/apache-tomcat-9.0.0.M8.tar.gz
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

[ -d $tomcat_home ] && echo "  Tomcat ${ver} already exits." && exit 0

[ -z $JAVA_HOME ] && echo "  Lost Java, install JDK first." && exit 1
systemctl status tomcat$ver >/dev/null && echo "  tomcat$ver already exist." exit 0

if ! grep -e "^${owner}" /etc/group >/dev/null; then
  echo "  create group: ${owner} (${gid})."
  groupadd -g $gid $owner
fi

if ! grep -e "^${owner}" /etc/passwd >/dev/null; then
  echo "  create user: ${owner} (${uid})."
  useradd -u $uid $owner -U -d $tomcat_home -s /sbin/nologin
fi

[ -d $workDir ] || mkdir -p $workDir || exit 1

url=$url_tomcat_src
source=$tomcat_src

echo "  Downloading Tomcat ..."
curl -fjkL $url -o $workDir/$source

[ -e $tomcat_home ] && mv $tomcat_home $tomcat_home.saved.$datetime

extracted=$(tar tf $workDir/$source | sed -n -e 1p | sed -e 's/\/.*//')
tar xf $workDir/$source -C $workDir
if [ ! -d $workDir/$extracted ]; then echo "  extract ${source} failed."; exit 1; fi
mv $workDir/$extracted $tomcat_home
if [ ! -d $tomcat_home ]; then echo "  set tomcat${ver} to ${path} failed."; exit 1; fi

if ! ls /usr/lib64 | grep tcnative >/dev/null; then
  echo "  install tomcat native ..."
  echo "  check build dependencies ..."
  [ -n $(rpm -qa automake) ] || yum install -y -q automake 1>/dev/null
  if [ -z $(rpm -qa automake) ]; then echo -e "  install package \"automake\" first."; exit 1; fi
  [ -n $(rpm -qa gcc) ] || yum install -y -q gcc 1>/dev/null
  if [ -z $(rpm -qa automake) ]; then echo -e "  install package \"gcc\" first."; exit 1; fi
  if [ -z $(rpm -qa | grep -e "apr.*-devel") ]; then
    [ -z $(yum repolist --disableplugin=* --disablerepo=* --enablerepo=ius | grep -e "^ius") ] || \
    if yum install -y -q apr15u-devel --enablerepo=ius 1>/dev/null; then
      withAPR=/usr/bin/apr15u-1-config
    elif yum install -y -q apr-devel >/dev/null; then
      withAPR=/usr/bin/apr-1-config
    else
      echo -e "  install package \"apr-devel\" first."
      exit 1
    fi
  fi

  if [ -z $(rpm -qa openssl-devel) ]; then
    [ -z $(yum repolist --disableplugin=* --disablerepo=* --enablerepo=furplag.github.io | grep -e "^furplag") ] || \
    yum install -y -q openssl-devel --enablerepo=furplag.github.io 1>/dev/null || yum install -y -q openssl-devel
    if [ -z $(rpm -qa openssl-devel) ]; then echo "  install package \"openssl-devel\" first."; exit 1; fi
  fi

  source=$(ls $tomcat_home/bin | grep tomcat-native.*.tar.gz)
  extracted=$(tar tf $tomcat_home/bin/$source | sed -n -e 1p | sed -e 's/\/.*//')
  tar xf $workDir/$source -C $workDir
  if [ ! -d $workDir/$extracted ]; then echo "  extract ${source} failed."; exit 1; fi
  cd $workDir/$extracted/native
  ./configure \
  --prefix=/usr \
  --libdir=/usr/lib64 \
  --with-java-home=$JAVA_HOME \
  --with-apr=$withAPR \
  --with-ssl=/usr/include/openssl 1>/dev/null 2>&1 && \
  make 1>/dev/null 2>&1 && \
  make install 1>/dev/null 2>&1
  cd "${currentDir}"
  if ! ls /usr/lib64 | grep tcnative >/dev/null; then echo "  extract ${source} failed."; exit 1; fi
fi

echo "  install tomcat daemon ..."
echo "  check build dependencies ..."
[ -n $(rpm -qa automake) ] || yum install -y -q automake 1>/dev/null
if [ -z $(rpm -qa automake) ]; then echo -e "  install package \"automake\" first."; exit 1; fi
[ -n $(rpm -qa gcc) ] || yum install -y -q gcc 1>/dev/null
if [ -z $(rpm -qa gcc) ]; then echo -e "  install package \"gcc\" first."; exit 1; fi
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

# instances
[ -d "/var/lib/tomcat${ver}s" ] && mv "/var/lib/tomcat${ver}s" "/var/lib/tomcat${ver}s.$datetime"
mkdir -p "/var/lib/tomcat${ver}s"
chown $owner:$owner "/var/lib/tomcat${ver}s"
chmod 0775 "/var/lib/tomcat${ver}s"
ln -s "/var/lib/tomcat${ver}s" $tomcat_home/instances

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

# environments
curl -fjkL https://raw.githubusercontent.com/furplag/linux-config-tips/master/rhel/webserver/tomcat/sysconfig.tomcat$ver.conf \
-o /etc/sysconfig/tomcat$ver
chown root:$owner /etc/sysconfig/tomcat$ver
chmod 0644 /etc/sysconfig/tomcat$ver

cat <<_EOT_>> $tomcat_home/conf/tomcat$ver.conf
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

# This variable is used to figure out if config is loaded or not.
TOMCAT_CFG_LOADED="1"

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
CATALINA_OPTS="-Xloggc:/usr/share/tomcat8/logs/gc.log -XX:+PrintGCDetails"
CATALINA_OPTS="-Djava.security.egd=file:/dev/./urandom"

_EOT_
[ $((echo "`java -version 2>&1`") | grep "java version" | cut -d "\"" -f 2 | cut -d "." -f 2) -gt 7 ] && \
sed -i -e 's/PermSize/MetaSpaceSize/g' $tomcat_home/conf/tomcat$ver.conf
chown tomcat:tomcat $tomcat_home/conf/tomcat$ver.conf
chmod 0664 $tomcat_home/conf/tomcat$ver.conf

cat <<_EOT_> /usr/lib/systemd/system/tomcat$ver.service
# Systemd unit file for default tomcat
# 
# To create clones of this service:
# DO NOTHING, use tomcat$ver@.service instead.

[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target

[Service]
Type=forking
EnvironmentFile=/etc/tomcat$ver/tomcat$ver.conf
Environment="NAME="
EnvironmentFile=-/etc/sysconfig/tomcat$ver

# replace "ExecStart" and "ExecStop" if you want tomcat runs as daemon
# ExecStart=/usr/share/tomcat$ver/bin/daemon.sh start
# ExecStop=/usr/share/tomcat$ver/bin/daemon.sh stop
ExecStart=/usr/share/tomcat$ver/bin/startup.sh
ExecStop=/usr/share/tomcat$ver/bin/shutdown.sh

SuccessExitStatus=143
User=$owner
Group=$owner

[Install]
WantedBy=multi-user.target

_EOT_
chmod 0644 /usr/lib/systemd/system/tomcat$ver.service

cp -p /usr/lib/systemd/system/tomcat$ver.service \
/usr/lib/systemd/system/tomcat$ver@.service

sed -i -e "s/tomcat${ver}@/\0name/g" \
-e 's/Environment="NAME=/\0\%I/g' \
-e "s/EnvironmentFile=-\/etc\/sysconfig\/tomcat${ver}/\0@\%I/g" \
/usr/lib/systemd/system/tomcat$ver@.service
chmod 644 /usr/lib/systemd/system/tomcat$ver@.service

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

sed -i -e 's/<Engine name="Catalina" defaultHost="localhost">/<Engine name="Catalina" jvmRoute="origin" defaultHost="localhost">/' \
-e 's/<\/Service>/<\!-- \n\0/' \
-e 's/<\/Server>/\0\n -->/' \
$tomcat_home/conf/server.xml

sslCert=$(grep -E "^[^\#]+SSLCertificateFile " /etc/httpd/conf.d/ssl.conf | sed -n -e 1p | sed -e 's/^.*SSLCertificateFile //')
sslKey=$(grep -E "^[^\#]+SSLCertificateKeyFile " /etc/httpd/conf.d/ssl.conf | sed -n -e 1p | sed -e 's/^.*SSLCertificateKeyFile //')

if [ -e $sslCert ] && [ -e $sslKey ]; then
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

echo "Done."
exit 0
