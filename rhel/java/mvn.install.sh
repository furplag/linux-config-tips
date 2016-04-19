#!/bin/sh
###
# mvn.install.sh
# https://github.com/furplag/linux-config-tips
# Copyright 2016 furplag
# Licensed under MIT (https://github.com/furplag/linux-config-tips/blob/master/LICENSE)

# Install Apache Maven relate \$JAVA_HOME
# 

# variables
version=${1:-3.3.9}

if [ ! $JAVA_HOME ]; then
  echo -e "env \$JAVA_HOME undifined."
  exit 1
elif [ -e $JAVA_HOME/bin/java ]; then
  echo -e "invalid path: \$JAVA_HOME=\"${JAVA_HOME}\", \"java\" not found."
  exit 1
fi

jdkVer=$(echo $JAVA_HOME | cut -d '.' -f 2)
if [ $jdkVer -lt 7 ]; then
  version=3.2.5
fi

curl -fLs https://www.apache.org/dist/maven/maven-3/$version/binaries/apache-maven-$version-bin.tar.gz \
 -o /tmp/apache-maven-$version-bin.tar.gz

if [ -e /tmp/apache-maven-$version-bin.tar.gz ]; then
  echo -e "source download failed."
  exit 1
fi

tar zxf /tmp/apache-maven-$version-bin.tar.gz -C /tmp

[ ! -e /tmp/apache-maven-$version ] && echo -e "source download failed." && exit 1

[ -e /usr/local/maven ] || mkdir -p /usr/local/maven
mv /tmp/apache-maven-$version /usr/local/.
