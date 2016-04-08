#!/bin/sh
###
# jdk.6.alternatives.sh
# https://github.com/furplag/linux-config-tips
# Copyright 2016 furplag
# Licensed under MIT (https://github.com/furplag/linux-config-tips/blob/master/LICENSE)

# Automatically setting up to use Java.
# 1. Set "alternatives" for JDK.
# 2. Set $JAVA_HOME (relate to alternatives config).

# variables
installJDK={$1:-1.6.0_45}
priority={$2:-`echo $installJDK | sed -e "s/[\.]//g" | sed -e "s/_/0/"`}

alternatives --remove java /usr/java/jdk$installJDK/bin/java >/dev/null 2>&1
alternatives --install /usr/bin/java java /usr/java/jdk$installJDK/bin/java $priority \
 --slave /usr/bin/appletviewer appletviewer /usr/java/jdk$installJDK/bin/appletviewer \
 --slave /usr/bin/extcheck extcheck /usr/java/jdk$installJDK/bin/extcheck \
 --slave /usr/bin/idlj idlj /usr/java/jdk$installJDK/bin/idlj \
 --slave /usr/bin/jar jar /usr/java/jdk$installJDK/bin/jar \
 --slave /usr/bin/jarsigner jarsigner /usr/java/jdk$installJDK/bin/jarsigner \
 --slave /usr/bin/javac javac /usr/java/jdk$installJDK/bin/javac \
 --slave /usr/bin/javadoc javadoc /usr/java/jdk$installJDK/bin/javadoc \
 --slave /usr/bin/javah javah /usr/java/jdk$installJDK/bin/javah \
 --slave /usr/bin/javap javap /usr/java/jdk$installJDK/bin/javap \
 --slave /usr/bin/jconsole jconsole /usr/java/jdk$installJDK/bin/jconsole \
 --slave /usr/bin/jdb jdb /usr/java/jdk$installJDK/bin/jdb \
 --slave /usr/bin/jhat jhat /usr/java/jdk$installJDK/bin/jhat \
 --slave /usr/bin/jinfo jinfo /usr/java/jdk$installJDK/bin/jinfo \
 --slave /usr/bin/jmap jmap /usr/java/jdk$installJDK/bin/jmap \
 --slave /usr/bin/jps jps /usr/java/jdk$installJDK/bin/jps \
 --slave /usr/bin/jrunscript jrunscript /usr/java/jdk$installJDK/bin/jrunscript \
 --slave /usr/bin/jsadebugd jsadebugd /usr/java/jdk$installJDK/bin/jsadebugd \
 --slave /usr/bin/jstack jstack /usr/java/jdk$installJDK/bin/jstack \
 --slave /usr/bin/jstat jstat /usr/java/jdk$installJDK/bin/jstat \
 --slave /usr/bin/jstatd jstatd /usr/java/jdk$installJDK/bin/jstatd \
 --slave /usr/bin/jvisualvm jvisualvm /usr/java/jdk$installJDK/bin/jvisualvm \
 --slave /usr/bin/native2ascii native2ascii /usr/java/jdk$installJDK/bin/native2ascii \
 --slave /usr/bin/rmic rmic /usr/java/jdk$installJDK/bin/rmic \
 --slave /usr/bin/schemagen schemagen /usr/java/jdk$installJDK/bin/schemagen \
 --slave /usr/bin/serialver serialver /usr/java/jdk$installJDK/bin/serialver \
 --slave /usr/bin/wsgen wsgen /usr/java/jdk$installJDK/bin/wsgen \
 --slave /usr/bin/wsimport wsimport /usr/java/jdk$installJDK/bin/wsimport \
 --slave /usr/bin/xjc xjc /usr/java/jdk$installJDK/bin/xjc \
 --slave /usr/bin/ControlPanel ControlPanel /usr/java/jdk$installJDK/jre/bin/ControlPanel \
 --slave /usr/bin/javaws javaws /usr/java/jdk$installJDK/jre/bin/javaws \
 --slave /usr/bin/jcontrol jcontrol /usr/java/jdk$installJDK/jre/bin/jcontrol \
 --slave /usr/bin/keytool keytool /usr/java/jdk$installJDK/jre/bin/keytool \
 --slave /usr/bin/orbd orbd /usr/java/jdk$installJDK/jre/bin/orbd \
 --slave /usr/bin/pack200 pack200 /usr/java/jdk$installJDK/jre/bin/pack200 \
 --slave /usr/bin/policytool policytool /usr/java/jdk$installJDK/jre/bin/policytool \
 --slave /usr/bin/rmid rmid /usr/java/jdk$installJDK/jre/bin/rmid \
 --slave /usr/bin/rmiregistry rmiregistry /usr/java/jdk$installJDK/jre/bin/rmiregistry \
 --slave /usr/bin/servertool servertool /usr/java/jdk$installJDK/jre/bin/servertool \
 --slave /usr/bin/tnameserv tnameserv /usr/java/jdk$installJDK/jre/bin/tnameserv \
 --slave /usr/bin/unpack200 unpack200 /usr/java/jdk$installJDK/jre/bin/unpack200

[ ! -e /etc/profile.d/java.sh ] && \
cat <<_EOT_ > /etc/profile.d/java.sh
# Set Environment with alternatives for Java VM.
export JAVA_HOME=\$(readlink /etc/alternatives/java | sed -e 's/\/bin\/java//g')
_EOT_

#alternatives --set java /usr/java/jdk$installJDK/bin/java && source /etc/profile
