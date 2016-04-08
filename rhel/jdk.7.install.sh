#!/bin/sh
###
# jdk.7.install.sh
# https://github.com/furplag/linux-config-tips
# Copyright 2016 furplag
# Licensed under MIT (https://github.com/furplag/linux-config-tips/blob/master/LICENSE)

# Automatically setting up to use Java.
# 1. Downloading JDK only use command-line.
# 2. Does not remove previous version of JDK, if "yum update jdk" runs.
# 3. Set "alternatives" for JDK.
# 4. Set $JAVA_HOME (relate to alternatives config).

# variables
resourceURL="http://download.oracle.com/otn-pub/java/jdk/7u80-b15/jdk-7u80-linux-x64.rpm"
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
  conflictUVer=`echo $conflictVer | cut -d "_" -f 2`
  if [ 6 -gt $conflictVer ]; then
    echo "    Ah, we have encountered Prehistoric JDK now !\n"
  elif [ $installVer -gt $conflictVer ]; then
    echo "    previous version of JDK ${conflictVer}.u${conflictUVer} has installed."
  elif [ $installJDK -gt $conflictJDK ]; then
    echo "    JDK ${conflictVer}u${conflictUVer} already installed."
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
      resourceURL=
    fi
  elif [ $installVer -gt $conflictVer ]; then
    echo "    escaping prehistoric version of JDK ..."
    tar cfz /tmp/stealth.jdk.tar.gz /usr/java/jdk1.[0-$conflictVer]* >/dev/null 2>&1
  else
    resourceURL=`echo $resourceURL | sed -e "s/rpm/tar.gz/"`
    resource=`echo $resource | sed -e "s/rpm/tar.gz/"`
  fi
elif [ -e /usr/java/jdk$installJDK ]; then
  echo "    JDK ${installVer}u${installUVer} (not managed package) already installed."
  resourceURL=
fi

if [ ! -e /tmp/$resource ] && [ "${resourceURL}" ]; then
  echo -e "\n  # Download Oracle JDK ${installVer}.\n" && \
    wget $resourceURL \
      --no-check-certificate \
      --no-cookies \
      --header "Cookie: oraclelicense=accept-securebackup-cookie" \
      -qNO /tmp/$resource
  if [ -e /tmp/$resource ] && [ `echo $resource | grep -e -v "rpm$" | wc -l` -gt 0 ]; then
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

if [ -e /usr/java/jdk$installJDK/bin/java ]; then
  wget https://raw.githubusercontent.com/furplag/linux-config-tips/master/rhel/jdk.$installVer.alternatives.sh \
    -qNO /tmp/jdk.$installVer.alternatives.sh && \
    chmod +x /tmp/jdk.$installVer.alternatives.sh && \
    /tmp/jdk.$installVer.alternatives.sh "${installJDK}" && \
    alternatived=true
elif [ -e /usr/java/jdk$conflictJDK/bin/java ]; then
  wget https://raw.githubusercontent.com/furplag/linux-config-tips/master/rhel/jdk.$installVer.alternatives.sh \
    -qNO /tmp/jdk.$installVer.alternatives.sh && \
    chmod +x /tmp/jdk.$installVer.alternatives.sh && \
    /tmp/jdk.$installVer.alternatives.sh "${conflictJDK}" && \
    alternatived=true
fi

if [ "${alternatived}" ]; then
  [ ! -e /etc/profile.d/java.sh ] && \
  echo -e "\n  # Set Environment \$JAVA_HOME (relate to alternatives config).\n"
cat <<_EOT_ > /etc/profile.d/java.sh
# Set Environment with alternatives for Java VM.
export JAVA_HOME=\$(readlink /etc/alternatives/java | sed -e 's/\/bin\/java//g')
_EOT_
  alternatives --set java /usr/java/jdk$installJDK/bin/java && source /etc/profile
fi

[ "${installSource}" ] && \
echo -e "\n  # Cleanup ...\n" && \
  rm -rf /tmp/$resource /tmp/$installSource /tmp/jdk.$installVer.alternatives.sh >/dev/null 2>&1

[ -e /tmp/stealth.jdk.tar.gz ] && \
  tar zxf /tmp/stealth.jdk.tar.gz -C /usr/java --strip=2 && \
  rm -rf /tmp/stealth.jdk.tar.gz

if [ -e /usr/java/jdk$installJDK ] && \
  echo -e "\n# Now complete to setting JDK ${installVer}u${installUVer}.\n" && \
  java -version
  [ "${JAVA_HOME}" ] && echo -e "JAVA_HOME:${JAVA_HOME}"
if [ "${alternatived}" ]; then
  echo -e "alternatives java: `alternatives --display java | grep -e "^\/usr\/java/jdk${installJDK}"`\n"
  echo -e "usage:\n# alternatives --config java && source /etc/profile\n"
fi
