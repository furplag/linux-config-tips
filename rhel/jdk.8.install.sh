#!/bin/sh
###
# jdk.8.install.sh
# https://github.com/furplag/linux-config-tips
# Copyright 2016 furplag
# Licensed under MIT (https://github.com/furplag/linux-config-tips/blob/master/LICENSE)

# Automatically setting up to use Java.
# 1. Downloading JDK only use command-line.
# 2. Does not remove previous version of JDK, if "yum update jdk" runs.
# 3. Set "alternatives" for JDK.
# 4. Set $JAVA_HOME (relate to alternatives config).

# variables
resourceURL="http://download.oracle.com/otn-pub/java/jdk/8u77-b03/jdk-8u77-linux-x64.rpm"
resource=`echo $resourceURL | sed -e "s/^.*\///"`
installVer=`echo $resource | cut -d "-" -f 2 | cut -d "u" -f 1`
installUVer=`echo $resource | cut -d "-" -f 2 | cut -d "u" -f 2`
installJDK=1.$installVer.0_$installUVer
installRoot=/usr/java
priority=`echo $installJDK | sed -e "s/[\.]//g" | sed -e "s/_/0/"`

if [ ! ${EUID:-${UID}} = 0 ]; then echo -e "Permission Denied, Root user only.\nHint: sudo ${0}"; exit 0; fi

echo -e "Oracle JDK ${installVer}u${installUVer} install with \"alternatives java\".\n"

echo -e "\n  # Checking installed package named \"jdk\".\n"
if [ "${conflictPackage=$(rpm -qa jdk | grep x86_64)}" ]; then
  conflictJDK=`echo $conflictPackage | cut -d "-" -f 2`
  conflictVer=`echo $conflictJDK | cut -d "." -f 2`
  conflictUVer=`echo $conflictJDK | cut -d "_" -f 2`
  if [ $installJDK = $conflictJDK ]; then
    echo "    JDK ${conflictVer}u${conflictUVer} already installed."
  elif [ 6 -gt $conflictVer ]; then
    echo "    Ah, we have encountered Prehistoric JDK now !\n"
  elif [ $installVer -gt $conflictVer ]; then
    echo "    previous version of JDK ${conflictVer}u${conflictUVer} has installed."
  elif [ $installVer -lt $conflictVer ]; then
    echo "    newer version of JDK ${conflictVer}u${conflictUVer} has installed."
  elif [ $installVer -eq $conflictVer ]; then
    if [ $installUVer -gt $conflictUVer ]; then
      echo "    previous version of JDK ${conflictVer}u${conflictUVer} has installed."
    else
      echo "    newer version of JDK ${conflictVer}u${conflictUVer} has installed."
    fi
  else
    echo "    newer version of JDK ${conflictVer}u${conflictUVer} has installed."
  fi
fi

if [ $conflictPackage ]; then
  if [ $installJDK = $conflictJDK ]; then
    resourceURL=
  elif [ $installVer -eq $conflictVer ]; then
    if [ $installUVer -gt $conflictUVer ]; then
      echo "    update JDK ${conflictVer}u${conflictUVer} to JDK ${installVer}u${installUVer}."
    else
      echo "    does not install JDK ${installVer}u${installUVer}."
      resourceURL=
    fi
  elif [ $installVer -gt $conflictVer ]; then
    echo "    escaping previous version of JDK ..."
    tar cfz /tmp/stealth.jdk.tar.gz /usr/java/jdk1.[0-$conflictVer]* >/dev/null 2>&1
  else
    resourceURL=`echo $resourceURL | sed -e "s/rpm/tar.gz/"`
    resource=`echo $resource | sed -e "s/rpm/tar.gz/"`
  fi
elif [ -e /usr/java/jdk$installJDK ]; then
  echo "    JDK ${installVer}u${installUVer} (not managed package) already installed."
  resourceURL=
fi

if [ "${resource}" ] && [ "${resourceURL}" ]; then
  echo -e "\n  # Download Oracle JDK ${installVer}.\n"
  wget $resourceURL \
    --no-check-certificate \
    --no-cookies \
    --header "Cookie: oraclelicense=accept-securebackup-cookie" \
    -qNO /tmp/$resource
  if [ -e /tmp/$resource ] && [ `echo $resource | grep -v -e "\.rpm$" | wc -l` -gt 0 ]; then
    echo "    unpacking ${resource} ..."
    tar zxf /tmp/$resource -C /tmp
    installSource="jdk${installJDK}"
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

if [ -e /usr/java/jdk$installJDK/bin/java ] || \
   [ -e /usr/java/jdk$conflictJDK/bin/java ]; then
  wget https://raw.githubusercontent.com/furplag/linux-config-tips/master/rhel/jdk.$installVer.alternatives.sh \
    -qNO /tmp/jdk.$installVer.alternatives.sh && \
    chmod +x /tmp/jdk.$installVer.alternatives.sh
  if [ -e /usr/java/jdk$installJDK/bin/java ]; then
    /tmp/jdk.$installVer.alternatives.sh "${installJDK}" && \
    alternatives --set java /usr/java/jdk$installJDK/bin/java
  else
    /tmp/jdk.$installVer.alternatives.sh "${conflictJDK}" && \
    alternatives --set java /usr/java/jdk$conflictJDK/bin/java
  fi
  [ ! -e /etc/profile.d/java.sh ] && \
  echo -e "\n  # Set Environment \$JAVA_HOME (relate to alternatives config).\n"
  cat <<_EOT_ > /etc/profile.d/java.sh
# Set Environment with alternatives for Java VM.
export JAVA_HOME=\$(readlink /etc/alternatives/java | sed -e 's/\/bin\/java//g')
_EOT_
  [ -e /etc/profile.d/java.sh ] && \
    source /etc/profile.d/java.sh
fi

echo -e "\n  # Cleanup ...\n"
rm -rf /tmp/$resource /tmp/$installSource /tmp/jdk.$installVer.alternatives.sh >/dev/null 2>&1

if [ "${conflictPackage}" ] && \
   [ $installVer -eq $conflictVer ] && \
   [ $installUVer -gt $conflictUVer ]; then
  alternatives --remove java /usr/java/jdk$conflictJDK/bin/java
fi

[ -e /tmp/stealth.jdk.tar.gz ] && \
  tar zxf /tmp/stealth.jdk.tar.gz -C /usr/java --strip=2 && \
  rm -rf /tmp/stealth.jdk.tar.gz

if [ -e /usr/java/jdk$installJDK ]; then
  echo -e "\n# Now complete to setting JDK ${installVer}u${installUVer}.\n"
  java -version
  [ "${JAVA_HOME}" ] && echo -e "JAVA_HOME:${JAVA_HOME}"
elif [ -e /usr/java/jdk$conflictJDK ]; then
  echo -e "\n# Now complete to setting JDK ${conflictVer}u${conflictUVer} (not changed).\n"
  java -version
  [ "${JAVA_HOME}" ] && echo -e "JAVA_HOME:${JAVA_HOME}"
else
  echo -e "\n# Install failed."
  [ `java -version 2>/dev/null | wc -l` -gt 0 ] && java -version
  [ "${JAVA_HOME}" ] && echo -e "JAVA_HOME:${JAVA_HOME}"
fi
[ -e /etc/alternatives/java ] && \
  echo -e "alternatives java:\n`alternatives --display java | grep -e "^\/usr\/java/.*\/bin\/java"`\n"
[ -e /etc/profile.d/java.sh ] && \
  echo -e "usage:\n# alternatives --config java && source /etc/profile\n"
