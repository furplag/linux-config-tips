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

# variables
javaDir=${1:-/usr/java}
mavenDir=${2:-/usr/maven}

echo -e "\nInstall Apache Maven"
if [ ! ${EUID:-${UID}} = 0 ]; then echo -e "\n  Permission Denied, Root user only.\n  Solution: sudo ${0}"; exit 0; fi

echo -e "\n  detect installed JDK(s) in \"${javaDir}\" ..."
if [ ! $javaDir ] || [ ! -d $javaDir ]; then
  echo -e "\n  directory \"${javaDir}\" not found."
  echo -e "  Solution:\n   1. Install JDK in \"${javaDir}\"."
  echo -e "   2. set argument directory installed JDK(s).\n      e.g.) ${0} /opt/java"
  exit 1
fi
javaVers=($(ls -F $javaDir | grep / | grep jdk | sed -e 's/\///' | sed -e 's/.*jdk//'))

javaClVer=$((java -version 2>&1) | grep -i version | cut -d '"' -f 2)
if [ ! $javaClVer ]; then
  echo -e "\n  java: command not found.\n  Solution: Set alternatives for \"java\"."
  exit 1
fi

[ $JAVA_HOME ] || JAVA_HOME=$(readlink -m $(which java) | sed -e 's/\/bin\/java$//')
[ -d $JAVA_HOME ] || JAVA_HOME=$(readlink -m $(which java) | sed -e 's/\/bin\/java$//')
javaEnvVer=$(($JAVA_HOME/bin/java -version 2>&1) | grep -i version | cut -d '"' -f 2)

if [ ! $javaEnvVer ]; then
  echo -e "\n  \"\$JAVA_HOME\" not defined."
  echo -e "  Solution:\n   1. \`export JAVA_HOME=/path/to/JDK/directory\`."
  exit 1
fi

[ "${javaClVer}" = "${javaEnvVer}" ] || \
 echo -e "\n  Warning:\n   `java` and `\$JAVA_HOME/bin/java` does not match."

[ -L /etc/alternatives/java ] || \
 echo -e "\n  Warning:\n   alternatives for java not defined."

echo -e "\n  \$JAVA_HOME: ${JAVA_HOME}\n  Java Version: ${javaClVer}\n  installed JDK version(s):"
[ $(echo ${javaVers[*]} | grep $javaClVer | wc -l) -gt 0 ] || \
 javaVers=("${javaVers[@]}" $javaClVer)
[ $(echo ${javaVers[*]} | grep $javaEnvVer | wc -l) -gt 0 ] || \
 javaVers=("${javaVers[@]}" $javaEnvVer)

for v in "${javaVers[@]}"; do
  echo -e "   ${v}"
done

[ -e $mavenDir ] || mkdir -p $mavenDir
for javaVer in "${javaVers[@]}"; do
  sourceUrl=https://www.apache.org/dist/maven/maven-3/@ver/binaries/apache-maven-@ver-bin.tar.gz
  jdkVer=$(echo $javaVer | cut -d '.' -f 2)
  mavenVer=3.3.9

  if [ $((jdkVer)) -lt 7 ]; then
    mavenVer=3.2.5
  elif [ $((jdkVer)) -lt 6 ]; then
    mavenVer=2.2.1
    sourceUrl=$(echo $sourceUrl | sed -e 's/www/archives/' | sed -e 's/\/maven-3\/@ver//')
  fi

  if [ -e $mavenDir/apache-maven-$mavenVer ]; then
    echo "  apache-maven-${mavenVer} already installed in \"${mavenDir}\"."
  else
    sourceUrl=$(echo $sourceUrl | sed -e "s/@ver/${mavenVer}/g")
    source=$(echo $sourceUrl | sed -e 's/.*\///g')
    echo "  downloading ${source} ..."
    curl -fLs "${sourceUrl}" -o /tmp/$source
    if [ ! -e /tmp/$source ]; then
      echo "   ${source} download failed."
    else
      tar zxf /tmp/$source -C $mavenDir
      if [ -e $mavenDir/apache-maven-$mavenVer ]; then
        echo -e "\n   ${source} installed in \"${mavenDir}\".\n"
         rm -f /tmp/$source >/dev/null 2>&1
      else
        echo "   ${source} install failed."
      fi
    fi
  fi

  if [ -e $mavenDir/apache-maven-$mavenVer ] &&
     [ $((jdkVer)) -gt 5 ] &&
     [ $(ls -F $javaDir | grep / | grep $javaVer | wc -l) -gt 0 ]; then
    sourceUrl=https://raw.githubusercontent.com/furplag/linux-config-tips/master/rhel/java/jdk.$jdkVer.alternatives.sh
    source=$(echo $sourceUrl | sed -e 's/.*\///g')
    if [ ! -e /tmp/$source ]; then
      curl -fLs "${sourceUrl}" -o /tmp/$source
       chmod +x /tmp/$source
      sed -i -e '$s/.*/\0 \\/' /tmp/$source
      echo -e " --slave /usr/bin/mvn mvn ${mavenDir}/apache-maven-${mavenVer}/bin/mvn \\" >> /tmp/$source
      echo -e " --slave /usr/bin/mvnDebug mvnDebug ${mavenDir}/apache-maven-${mavenVer}/bin/mvnDebug \\" >> /tmp/$source
      echo -e " --slave /usr/bin/mvnyjp mvnyjp ${mavenDir}/apache-maven-${mavenVer}/bin/mvnyjp\n" >> /tmp/$source
      /tmp/$source ${javaVer}
      #rm -f /tmp/$source
    fi
  fi
done
exit 0
