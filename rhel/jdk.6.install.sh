#!/bin/sh
###
# jdk.6.install.sh
# https://github.com/furplag/linux-config-tips
# Copyright 2016 furplag
# Licensed under MIT (https://github.com/furplag/linux-config-tips/blob/master/LICENSE)

# Automatically setting up to use Java.
# 1. Downloading JDK only use command-line.
# 2. Does not remove previous version of JDK, if "yum update jdk" runs.
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

if [ ! ${EUID:-${UID}} = 0 ]; then echo -e "Permission Denied, Root user only.\nHint: sudo ${0}"; exit 0; fi

echo -e "Oracle JDK ${installVer}u${installUVer} install with \"alternatives java\".\n"

echo -e "\n  # Checking installed package named \"jdk\".\n"
if [ "${conflictPackage=$(rpm -qa jdk | grep x64)}" ]; then
  conflictJDK=`echo $conflictPackage | cut -d "-" -f 2`
  conflictVer=`echo $conflictJDK | cut -d "." -f 2`
  conflictUVer=`echo $conflictVer | cut -d "_" -f 2`
  if [ $installVer -gt $conflictVer ]; then
    echo "    Ah, we have encountered Prehistoric JDK now !\n"
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
  echo -e "\n  # Download Oracle JDK ${installVer}.\n" && \
    wget $resourceURL \
      --no-check-certificate \
      --no-cookies \
      --header "Cookie: oraclelicense=accept-securebackup-cookie" \
      -qON /tmp/$resource
  if [ -e /tmp/$resource ] && [ `echo $resource | grep -e "bin$"` ]; then
    echo "    unpacking ${resource} ..." && \
    chmod +x /tmp/$resource
    if [ `echo $resource | grep -e "\-rpm"` ]; then
      installSource=`unzip -l /tmp/$resource -x sun-javadb* 2>/dev/null | grep rpm | grep -v -e "${resource}$" | sed -e "s/.*\s//"`
      unzip -o /tmp/$resource -d /tmp -x sun-javadb* >/dev/null 2>&1
    else
      /tmp/$resource -x
      installSource="jdk${installJDK}"
      if [ -e "${installSource}" ]; then
        mv $installSource /tmp
      else
        installSource=
      fi
    fi
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
  wget -qN https://raw.githubusercontent.com/furplag/linux-config-tips/master/rhel/jdk.6.alternatives.sh && \
    chmod +x jdk.6.alternatives.sh && \
    ./jdk.6.alternatives.sh "${installJDK}"
  rm -f jdk.6.alternatives.sh
fi

[ ! -e /etc/profile.d/java.sh ] && \
echo -e "\n  # Set Environment \$JAVA_HOME (relate to alternatives config).\n"
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
