#!/bin/sh
###
# mvn.install.sh
# https://github.com/furplag/linux-config-tips
# Copyright 2016 furplag
# Licensed under MIT (https://github.com/furplag/linux-config-tips/blob/master/LICENSE)

# Install Apache Maven relate \$JAVA_HOME
# 1. Download Apache Maven 3.
# 3. Set "alternatives" for Maven.
# 4. Set $M2, $M2_HOME (relate to $JAVA_HOME).

if [ ! ${EUID:-${UID}} = 0 ]; then echo -e "Permission Denied, Root user only.\nHint: sudo ${0}"; exit 0; fi

echo "\nInstall Apache Maven ..."

if [ $((java -version 2>&1) | grep -i version | wc -l) -gt 0 ]; then
  javaVer=$((java -version 2>&1) | grep -i version | cut -d '"' -f 2)
elif [ $((java -version 2>&1) | grep -i version | wc -l) -gt 0 ]; then
  javaVer=$(($JAVA_HOME/bin/java -version 2>&1) | grep -i version | cut -d '"' -f 2)
fi

jdkVer=$((echo $javaVer) | cut -d '.' -f 2)
if [ 0 -eq $((jdkVer)) ]; then
  echo -e "\n  Could not detect java."
  if [ $(find / -type f -name java -not -type l | grep -v alternatives | grep -v jre | wc -l) -gt 0 ]; then
    echo -e "\n  Solution:\n  1. set \$PATH to jdk.\n  2. set alternatives java.\n  \"java\" found in ..."
    find / -type f -name java -not -type l | grep -v alternatives | grep -v jre | sed -e 's/^./    \0/'
  else
    echo -e "\n  Install JDK first."
  fi
  exit 1
elif [ 6 -gt $((jdkVer)) ]; then
  echo -e "\n  Ah, we have encountered Prehistoric JDK now !\n\n  The Great Maven III said, \"N E W E R J D K\".\n"
  exit 1
else
  echo -e "\n  currently JDK $(echo $javaVer | cut -d '.' -f 2,3 | sed -e 's/\.0_/u/') has defined as a command of \`java\`."
fi

[ -e /usr/local/mvn ] || mkdir -p /usr/local/mvn
for mavenVer in 3.2.5 3.3.9; do
  if [ -e /usr/local/mvn/apache-maven-$mavenVer ]; then continue; fi
  echo -e "\n  Download Apache maven ${mavenVer} ..."
  curl -fLs https://www.apache.org/dist/maven/maven-3/$mavenVer/binaries/apache-maven-$mavenVer-bin.tar.gz \
   -o /tmp/apache-maven-$mavenVer-bin.tar.gz
  [ -e /tmp/apache-maven-$mavenVer-bin.tar.gz ] && \
   tar zxf /tmp/apache-maven-$mavenVer-bin.tar.gz -C /usr/local/mvn
  if [ ! -e /usr/local/mvn/apache-maven-$mavenVer ]; then
    echo "    maven-${mavenVer} install failed."
    continue
  fi
  alternatives --remove mvn /usr/local/mvn/apache-maven-$mavenVer >/dev/null 2>&1
  alternatives --install /usr/local/bin/mvn mvn /usr/local/mvn/apache-maven-$mavenVer/bin/mvn $(echo $mavenVer | sed -e 's/\./0/g') \
   --slave /usr/local/bin/mvnDebug mvnDebug /usr/local/mvn/apache-maven-$mavenVer/bin/mvnDrbug \
   --slave /usr/local/bin/mvnyjp mvnyjp /usr/local/mvn/apache-maven-$mavenVer/bin/mvnyjp
  if [ $(((alternatives --display mvn) | grep $mavenVer/bin/mvn | wc -l)) -gt 0 ]; then
    echo "    maven-${mavenVer} installed in \"/usr/local/mvn/apache-maven-${mavenVer}\"."
  else
    echo "    maven-${mavenVer} install failed."
  fi
done

[ -e /etc/profile.d/mvn.sh ] || cat << _EOT_ > /etc/profile.d/mvn.sh
#/etc/profile.d/mvn.sh

# Set Environment with alternatives for Apache Maven.
if [ \$JAVA_HOME ]; then
  jdkVer=((\$JAVA_HOME/bin/java -version 2>&1) | grep -i version | cut -d '"' -f 2 | cut -d '.' -f 2)
elif [ $(((which java 2>&1) | grep -e "\/bin\/java" | wc -l)) -gt 0 ]; then
  export JAVA_HOME=((which java 2>&1) | sed -e 's/\/bin\/java//')
  jdkVer=((\$JAVA_HOME/bin/java -version 2>&1) | grep -i version | cut -d '"' -f 2 | cut -d '.' -f 2)
fi

if [ \$((jdkVer)) -gt 6 ]; then
  alternatives --set mvn /usr/local/maven/apache-maven-3.3.9/bin/mvn
elif [ \$((jdkVer)) -gt 4 ]; then
  alternatives --set mvn /usr/local/maven/apache-maven-3.2.5/bin/mvn
else
  exit 0
fi
export M2_HOME=(readlink -m \$(which mvn) | sed -e 's/\/bin\/mvn//')
export M2=\$M2_HOME/bin

_EOT_

