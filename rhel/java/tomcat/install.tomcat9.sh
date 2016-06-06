useradd -u 91 tomcat -U -r -s /sbin/nologin

curl -fjkLO http://www-us.apache.org/dist/tomcat/tomcat-9/v9.0.0.M6/bin/apache-tomcat-9.0.0.M6.tar.gz

tar xf apache-tomcat-9.0.0.M6.tar.gz -C /usr/share

mv /usr/share/apache-tomcat-9.0.0.M6 /usr/share/tomcat9

chown root:tomcat -R /usr/share/tomcat9/
chown root:tomcat -R /usr/share/tomcat9/*

mv /usr/share/tomcat9/conf /etc/tomcat9/conf
ln -s /etc/tomcat9/conf /usr/share/tomcat9/conf

mv /usr/share/tomcat9/logs /var/log/tomcat9
ln -s /var/log/tomcat9 /usr/share/tomcat9/logs

mkdir /var/cache/tomcat9
chown root:tomcat -R /var/cache/tomcat9/
mv /usr/share/tomcat9/temp var/cache/tomcat9/temp
ln -s /var/cache/tomcat9/temp /usr/share/tomcat9/temp
mv /usr/share/tomcat9/work var/cache/tomcat9/work
ln -s /var/cache/tomcat9/work /usr/share/tomcat9/work

mkdir /var/lib/tomcat9
chown root:tomcat /var/lib/tomcat9
mv /usr/share/tomcat9/webapps /var/lib/tomcat9/webapps

mkdir /var/lib/tomcat9s
chown root:tomcat /var/lib/tomcat9s

> /var/run/tomcat9.pid
chown root:tomcat /var/run/tomcat9.pid

mkdir /etc/tomcat9/Catalina
mkdir /etc/tomcat9/Catalina/localhost
chown root:tomcat /etc/tomcat9/Catalina
chown root:tomcat /etc/tomcat9/Catalina/localhost

cat <<_EOT_> /etc/sysconfig/tomcat9
# Service-specific configuration file for tomcat. This will be sourced by
# the SysV init script after the global configuration file
# /etc/tomcat/tomcat.conf, thus allowing values to be overridden in
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

cat <<_EOT_> /etc/tomcat9/tomcat9.conf
# System-wide configuration file for tomcat services
# This will be loaded by systemd as an environment file,
# so please keep the syntax.
#
# There are 2 "classes" of startup behavior in this package.
# The old one, the default service named tomcat9.service.
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
chown root:tomcat /etc/tomcat9/tomcat9.conf

mkdir /usr/libexec/tomcat9
cat <<_EOT_> /usr/libexec/tomcat9/functions
#!/bin/bash

if [ -r /usr/share/java-utils/java-functions ]; then
  . /usr/share/java-utils/java-functions
else
  echo "Can't read Java functions library, aborting"
  exit 1
fi

_save_function() {
    local ORIG_FUNC=\$(declare -f \$1)
    local NEWNAME_FUNC="\$2\${ORIG_FUNC#\$1}"
    eval "\$NEWNAME_FUNC"
}

run_jsvc(){
    if [ -x /usr/bin/jsvc ]; then
	TOMCAT_USER="tomcat"
       	JSVC="/usr/bin/jsvc"
	
	JSVC_OPTS="-nodetach -pidfile /var/run/jsvc-tomcat\${NAME}.pid -user \${TOMCAT_USER} -outfile \${CATALINA_BASE}/logs/catalina.out -errfile \${CATALINA_BASE}/logs/catalina.out"
	if [ "\$1" = "stop" ]; then
		JSVC_OPTS="\${JSVC_OPTS} -stop"
    	fi

        exec "\${JSVC}" \${JSVC_OPTS} \${FLAGS} -classpath "\${CLASSPATH}" \${OPTIONS} "\${MAIN_CLASS}" "\${@}"
    else
       	echo "Can't find /usr/bin/jsvc executable"
    fi

}

_save_function run run_java

run() {
   if [ "\${USE_JSVC}" = "true" ] ; then
	run_jsvc \$@
   else
	run_java \$@
   fi
}

_EOT_

cat <<_EOT_> /usr/libexec/tomcat9/preamble
#!/bin/bash

. /usr/libexec/tomcat9/functions

# Get the tomcat config (use this for environment specific settings)

if [ -z "\${TOMCAT_CFG_LOADED}" ]; then
  if [ -z "\${TOMCAT_CFG}" ]; then
    TOMCAT_CFG="/etc/tomcat9/tomcat.conf"
  fi
  . \$TOMCAT_CFG
fi

if [ -z "\$CATALINA_BASE" ]; then
  if [ -n "\$NAME" ]; then
    if [ -z "\$TOMCATS_BASE" ]; then
      TOMCATS_BASE="/var/lib/tomcat9s/"
    fi
    CATALINA_BASE="\${TOMCATS_BASE}\${NAME}"
  else
    CATALINA_BASE="\${CATALINA_HOME}"
  fi
fi
VERBOSE=1
set_javacmd
cd \${CATALINA_HOME}
# CLASSPATH munging
if [ ! -z "\$CLASSPATH" ] ; then
  CLASSPATH="\$CLASSPATH":
fi

if [ -n "\$JSSE_HOME" ]; then
  CLASSPATH="\${CLASSPATH}\$(build-classpath jcert jnet jsse 2>/dev/null):"
fi
CLASSPATH="\${CLASSPATH}\${CATALINA_HOME}/bin/bootstrap.jar"
CLASSPATH="\${CLASSPATH}:\${CATALINA_HOME}/bin/tomcat-juli.jar"
CLASSPATH="\${CLASSPATH}:\$(build-classpath commons-daemon 2>/dev/null)"

if [ -z "\$LOGGING_PROPERTIES" ] ; then
  LOGGING_PROPERTIES="\${CATALINA_BASE}/conf/logging.properties"
  if [ ! -f "\${LOGGING_PROPERTIES}" ] ; then
    LOGGING_PROPERTIES="\${CATALINA_HOME}/conf/logging.properties"
  fi
fi

_EOT_

cat <<_EOT_> /usr/libexec/tomcat9/server
#!/bin/bash

. /usr/libexec/tomcat9/preamble

MAIN_CLASS=org.apache.catalina.startup.Bootstrap

FLAGS="\$JAVA_OPTS \$CATALINA_OPTS"
OPTIONS="-Dcatalina.base=\$CATALINA_BASE \
-Dcatalina.home=\$CATALINA_HOME \
-Djava.endorsed.dirs=\$JAVA_ENDORSED_DIRS \
-Djava.io.tmpdir=\$CATALINA_TMPDIR \
-Djava.util.logging.config.file=\${LOGGING_PROPERTIES} \
-Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager"

if [ "\$1" = "start" ] ; then
  if [ "\${SECURITY_MANAGER}" = "true" ] ; then
    OPTIONS="\${OPTIONS} \
    -Djava.security.manager \
    -Djava.security.policy==\${CATALINA_BASE}/conf/catalina.policy"
  fi
  run start
elif [ "\$1" = "stop" ] ; then
  run stop
fi

_EOT_

chown root:tomcat /usr/libexec/tomcat9/
chown root:tomcat -R /usr/libexec/tomcat9/*

cat <<_EOT_> /usr/systemd/system/tomcat.service
# Systemd unit file for default tomcat
# 
# To create clones of this service:
# DO NOTHING, use tomcat@.service instead.

[Unit]
Description=Apache Tomcat Web Application Container
After=syslog.target network.target

[Service]
Type=simple
EnvironmentFile=/etc/tomcat9/tomcat9.conf
Environment="NAME="
EnvironmentFile=-/etc/sysconfig/tomcat9
ExecStart=/usr/libexec/tomcat9/server start
ExecStop=/usr/libexec/tomcat9/server stop
SuccessExitStatus=143
User=tomcat
Group=tomcat


[Install]
WantedBy=multi-user.target

_EOT_

cat <<_EOT_> /usr/systemd/system/tomcat9@.service
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
Type=simple
EnvironmentFile=/etc/tomcat9/tomcat9.conf
Environment="NAME=%I"
EnvironmentFile=-/etc/sysconfig/tomcat9@%I
ExecStart=/usr/libexec/tomcat9/server start
ExecStop=/usr/libexec/tomcat9/server stop
SuccessExitStatus=143
User=tomcat
Group=tomcat

[Install]
WantedBy=multi-user.target

_EOT_

