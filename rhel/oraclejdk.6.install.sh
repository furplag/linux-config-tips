#!/bin/sh
###
# oraclejdk.6.install.sh
# https://github.com/furplag/linux-config-tips
# Copyright 2016 furplag
# Licensed under MIT (https://github.com/furplag/linux-config-tips/blob/master/LICENSE)

# Automatically setting up to Java.
# 1. Downloading JDK only use command-line.
# 2. Does not remove previous version of JDK, if yum update jdk runs.
# 3. Set "alternatives" for JDK.
# 4. Set $JAVA_HOME (relate to alternatives config).

# variables
resourceURL="http://download.oracle.com/otn-pub/java/jdk/6u45-b06/jdk-6u45-linux-x64-rpm.bin"
resource=`echo $resourceURL | sed -e "s/^.*\///"`
installVer=`echo $resource | cut -d "-" -f 2 | cut -d "u" -f 1`
installUVer=`echo $resource | cut -d "-" -f 2 | cut -d "u" -f 2`
installJDK=1.$installVer.0_$installUVer
installRoot=/usr/java
priority=`echo $installJDK | sed -e "s/[\.]//g" | sed -e "s/_/0/"`

echo -e "Oracle JDK ${installVer}u${installUVer} install with alternatives\n"

echo -e "\n  # Checking installed package named \"jdk\".\n"
if [ "${conflictPackage=$(rpm -qa jdk)}" ]; then
  conflictJDK=`echo $conflictPackage | cut -d "-" -f 2`
  conflictVer=`echo $conflictJDK | cut -d "." -f 2`
  conflictUVer=`echo $conflictVer | cut -d "_" -f 2`
  if [ $installVer -gt $conflictVer ]; then
    echo "    Ah, we have encountered Prehistoric JDK now !"
  fi
  echo -e "    ${conflictPackage} already installed."
fi

echo -e "\n  # Detect installed package detail.\n"

if [ $conflictPackage ]; then
  if [ $installJDK = $conflictJDK ]; then
    resourceURL=
  elif [ $installVer -eq $conflictVer ]; then
    if [ $installUVer -gt $conflictUVer ]; then
      echo "    previous version of JDK ${conflictVer} (1.${conflictVer}.0_${conflictUVer}) has installed."
    else
      echo "    newer version of JDK ${conflictVer} (1.${conflictVer}.0_${conflictUVer}) has installed."
      resourceURL=
    fi
  elif [ $installVer -gt $conflictVer ]; then
    echo "    escaping prehistoric version of JDK ..."
    tar cfz /tmp/stealth.jdk.tar.gz /usr/java/jdk1.[0-$conflictVer]* >/dev/null 2>&1
  else
    echo "    newer version of JDK ${conflictVer} has installed."
    resourceURL=`echo $resourceURL | sed -e "s/\-rpm//"`
    resource=`echo $resource | sed -e "s/\-rpm//"`
  fi
elif [ -e /usr/java/jdk$installJDK ]; then
  echo "    jdk-${installJDK} (not managed package) already installed."
  resourceURL=
fi



if [ ! -e /tmp/$resource ] && [ "${resourceURL}" ]; then
  echo -e "\n  # Download Oracle JDK ${installVer} without single-sign-on\n" && \
    wget $resourceURL \
      --no-check-certificate \
      --no-cookies \
      --header "Cookie: oraclelicense=accept-securebackup-cookie" \
      -qO /tmp/$resource
  if [ -e /tmp/$resource ] && [ `echo $resource | grep -e "bin$"` ]; then
    echo "    unpacking ${resource} ..." && \
    chmod +x /tmp/$resource && \
    installSource=`unzip -l /tmp/$resource -x sun-javadb* 2>/dev/null | grep rpm | grep -v -e "${resource}$" | sed -e "s/.*\s//"`
    unzip -o /tmp/$resource -d /tmp -x sun-javadb* >/dev/null 2>&1
  elif [ -e /tmp/$resource ]; then
    installSource=$resource
  fi
fi

if [ "${installSource}" ] && [ -e /tmp/$installSource ]; then
  echo -e "\n  # Install JDK package.\n"
  if [ `echo $installSource | grep -e "rpm$" | wc -l` -gt 0 ]; then
    yum install -y /tmp/$installSource >/dev/null 2>&1
  else
    [ ! -e /usr/java ] && mkdir /usr/java
    mv /tmp/$installSource /usr/java/$installSource
  fi
fi

echo "  # Setting up \"alternatives\" for \"java\"."

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

alternatives --set java /usr/java/jdk$installJDK/bin/java && source /etc/profile

[ "${installSource}" ] && \
echo -e "\n  # Cleanup ...\n" && \
  rm -rf /tmp/$resource /tmp/$installSource >/dev/null 2>&1

[ -e /tmp/stealth.jdk.tar.gz ] && \
  tar zxf /tmp/stealth.jdk.tar.gz -C /usr/java --strip=2 && \
  rm -rf /tmp/stealth.jdk.tar.gz

echo -e "\n# Now complete to setting JDK ${installVer}u${installUVer}.\n"
java -version
echo -e "JAVA_HOME:${JAVA_HOME}"
echo -e "alternatives java: `alternatives --display java | grep -e "^\/usr\/java/jdk${installJDK}"`\n"
echo -e "usage:\n# alternatives --config java && source /etc/profile\n"
