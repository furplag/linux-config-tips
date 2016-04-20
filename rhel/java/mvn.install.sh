#!/bin/sh
###
# mvn.install.sh
# https://github.com/furplag/linux-config-tips
# Copyright 2016 furplag
# Licensed under MIT (https://github.com/furplag/linux-config-tips/blob/master/LICENSE)

# Install Apache Maven relate \$JAVA_HOME
# 

# variables
javaVer=((java -version 2>&1) | grep -i version | cut -d '"' -f 2)
if [ $javaVer ]; then
  jdkVer=$javaVer | cut -d '.' -f 2
elif [ $JAVA_HOME ]; then
  javaVer=(($JAVA_HOME/bin/java -version 2>&1) | grep -i version | cut -d '"' -f 2)
  jdkVer=$javaVer | cut -d '.' -f 2
fi

if [ ! $jdkVer ]; then
  echo -e "\n  Java VM not difined, Install JDK first."
  exit 1
elif [ $((jdkVer)) -lt 5 ]; then
  echo -e "\n  Ah, we have encountered Prehistoric JDK now !"
  echo -e "\n  The Great Maven says, \"N E W E R\"."
  exit 1
fi

[ -e /usr/local/maven ] || mkdir -p /usr/local/maven
for mavenVer in 3.2.5 3.3.9; do
  if [ -e /usr/local/maven/apache-maven-$mavenVer ]; then continue; fi
  echo -e "\n  Download Apache maven ${mavenVer} ..."
  curl -fLs https://www.apache.org/dist/maven/maven-3/$mavenVer/binaries/apache-maven-$mavenVer-bin.tar.gz \
   -o /tmp/apache-maven-$mavenVer-bin.tar.gz
  [ -e /tmp/apache-maven-$mavenVer-bin.tar.gz ] && \
   tar zxf /tmp/apache-maven-$mavenVer-bin.tar.gz -C /usr/local/maven
  if [ ! -e /usr/local/maven/apache-maven-$mavenVer ]; then
    echo "    maven-${mavenVer} install failed."
    continue
  fi
  alternatives --remove mvn /usr/local/maven/apache-maven-$mavenVer >/dev/null 2>&1
  alternatives --install /usr/local/bin/mvn mvn /usr/local/maven/apache-maven-$mavenVer/bin/mvn $(echo $mavenVer | sed -e 's/\./0/g') \
   --slave /usr/local/bin/mvnDebug mvnDebug /usr/local/maven/apache-maven-$mavenVer/bin/mvnDrbug \
   --slave /usr/local/bin/mvnyjp mvnyjp /usr/local/maven/apache-maven-$mavenVer/bin/mvnyjp
  if [ $(((alternatives --display mvn) | grep $mavenVer/bin/mvn | wc -l)) -gt 0 ]; then
    echo "    maven-${mavenVer} installed in \"/usr/local/maven\"."
    [ -e /etc/profile.d/mvn.sh ] || cat << _EOT_ > /etc/profile.d/mvn.sh
#/etc/profile.d/mvn.sh

# Set Environment with alternatives for Apache Maven.
[ $JAVA_HOME ] || exit 0
export JAVA_HOME=\$(readlink /etc/alternatives/java | sed -e 's/\/bin\/java//g')
_EOT_

done


