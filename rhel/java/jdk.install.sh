#!/bin/sh
set -ue -o pipefail
export LC_ALL=C
###
# jdk.install.sh
# https://github.com/furplag/linux-config-tips
# Copyright 2016 furplag
# Licensed under MIT (https://github.com/furplag/linux-config-tips/blob/master/LICENSE)
# 
# Automatically setting up to use Java.
#   1. Install Oracle JDK.
#   2. Does not remove previous version of JDK, if "yum update jdk" runs.
#   3. Set "alternatives" for JDK.
#   4. Set $JAVA_HOME (relate to alternatives config).
#   5. Install Apache Maven as java alternatives slaves (optional) .

# variables
declare -r name=`basename $0`
declare -r datetime=`date +"%Y%m%d%H%M%S"`
declare -r jdkDir=/usr/java
declare -r workDir=$jdkDir/install.log/$datetime
declare -r baseURL=https://edelivery.oracle.com/otn-pub/java/jdk/@nameOfVer@/jdk-@ver@u@updateVer@-linux-x64.rpm
declare -r defaultVer=8u92-b14
declare -r stealth=$workDir/stealth.JDK.tar.gz
declare -r mavenDir=/usr/maven
declare -r mavenBaseURL=https://www.apache.org/dist/maven/maven-3/@mavenVer/binaries/
declare -r mavenSourceBase=apache-maven-@mavenVer
declare -r scriptURL=https://raw.githubusercontent.com/furplag/linux-config-tips/master/rhel/java/

declare verStr=
declare nameOfVer=
declare installVer=
declare -i ver=
declare -i updateVer=
declare -i buildVer=

declare downloadURL=
declare downloadSource=
declare installSource=
declare javaHomes=()
declare finder=()
declare conflicts=()
declare embed=false

declare maven=false
declare mavenVer=
declare mavenSource=

###
# functions

# Usage
usage(){
  cat << _EOT_
Name: ${name}
Description:
  1. Install Oracle JDK.
  2. Does not remove previous version of JDK, if "yum update jdk" runs.
  3. Set "alternatives" for JDK.
  4. Set \$JAVA_HOME (relate to alternatives config).
  5. Install Apache Maven as java alternatives slaves (optional) .
Requirement:
  1. root user executable only.
  2. Installable JDK version: 5 - 8.
Usgae: ${name} [-v jdkVersion] [-m]
  -v : install JDK version (optional, default : $defaultVer)
       (1.)[version]
         5 : 5u22
         6 : 6u45-b06
         7 : 7u80-b15
         8 : 8u92-b14
       (1.)[version].0_[updateVersion](-b[build])
       [version]u[updateVersion]-b[build]
       Note : Use "u0" or ".0(_00)", if you need to install base version. 
              e.g.) \`$name -v 1.6.0\` \`$name -v 8.0-b132\`
  -m : install maven (optional, default : false)
       JDK 5 : maven-2.2.1
       JDK 6 : maven-3.2.5
       JDK 7 : maven-3.3.9
       JDK 8 : maven-3.3.9
_EOT_
}

if [ ${EUID:-${UID}} -ne 0 ]; then usage; echo -e "\nPermission Denied, Root user only.\nHint: sudo ${0}"; exit 1; fi

# options
while getopts hmv: OPT; do
  case $OPT in
    v) verStr=${OPTARG:-${defaultVer}};;
    m) maven=true;;
    h) usage; exit 1;;
    \?) usage; exit 1;;
  esac
done

# "v" option header had been omitted.
if [ -z $verStr ] && [ $# -eq 0 ]; then
  verStr=$defaultVer
elif [ -z $verStr ] && [ $# -eq 1 ] && [ "${1}" = "-m" ]; then
  verStr=$defaultVer
  maven=true
elif [ -z $verStr ] && [ $# -eq 1 ]; then
  verStr="${1}"
elif [ -z $verStr ] && [ $# -eq 2 ] && [ "${1}" = "-m" ]; then
  verStr="${2}"
elif [ -z $verStr ] && [ $# -eq 2 ] && [ "${2}" = "-m" ]; then
  verStr="${1}"
fi

# validate
if [[ $verStr =~ ^(1\.)?6(u|\.0_)4(\-b12)?$ ]]; then
  nameOfVer=6u4-b12
elif [[ $verStr =~ ^(1\.)?6(u|\.0_)5(b)?$ ]]; then
  nameOfVer=6u5b
elif [[ $verStr =~ ^(1\.)?[5-9](u|\.0_)[0-9]{1,4}(\-b[0-9]{1,4})?$ ]]; then
  nameOfVer=$(echo $verStr | sed -e 's/^1\.//' | sed -e 's/\.0_/u/')
elif [[ $verStr =~ ^(1\.)?[5-9]\.0(\-b[0-9]{1,4})?$ ]]; then
  nameOfVer=$(echo $verStr | sed -e 's/^1\.//' | sed -e 's/\.0/u0/')
elif [[ $verStr =~ ^(1\.)?[5-9]$ ]]; then
  ver=$(echo $verStr | sed -e 's/^1\.//')
  case $ver in
    5) nameOfVer=5u22;;
    6) nameOfVer=6u45-b06;;
    7) nameOfVer=7u80-b15;;
    8) nameOfVer=8u92-b14;;
  esac
else
  usage
  exit 1
fi

ver=$(echo $nameOfVer | sed -e 's/u.*//')
installVer=1.$ver.0
updateVer=$(echo $nameOfVer | sed -e 's/.*u//' | sed -e 's/-.*//' | sed -e 's/b$//')
if [ $updateVer -eq 0 ]; then
  nameOfVer=$(echo $nameOfVer | sed -e 's/u0//')
else
  installVer="${installVer}_$(printf "%02d" $updateVer)"
fi
if [[ $nameOfVer =~ \-b[0-9]{1,4}$ ]]; then
  buildVer=$(echo $nameOfVer | sed -e 's/.*b//')
fi
[[ $installVer =~ ^1\.(0|([1-9]+[0-9]*))\.0(_(0[1-9]|[1-9]+[0-9]+))?$ ]] || installVer=

# generate source URL
if [ -n $installVer ]; then
  if [ $ver -lt 6 ]; then
    downloadURL=$(echo $baseURL | sed -e "s/@nameOfVer@/${installVer}/")
    downloadURL=$(echo $downloadURL | sed -e "s/@ver@u@updateVer@/$(echo $installVer | sed -e 's/\./_/g')/")
    downloadURL=$(echo $downloadURL | sed -e 's/\-x64/\-amd64/' | sed -e 's/\.rpm$/\-rpm\.bin/')
  else
    downloadURL=$(echo $baseURL | sed -e "s/@nameOfVer@/${nameOfVer}/")
    downloadURL=$(echo $downloadURL | sed -e "s/@ver@/${ver}/" | sed -e "s/@updateVer@/${updateVer}/")
    if [ $ver -eq 6 ]; then
      downloadURL=$(echo $downloadURL | sed -e 's/\.rpm$/-rpm.bin/')
      [ $updateVer -gt 3 ] || downloadURL=$(echo $downloadURL | sed -e 's/x64/amd64/')
      [ $updateVer -lt 11 ] || [ $buildVer -gt 0 ] || downloadURL=
    elif [ $buildVer -eq 0 ]; then
      downloadURL=
    fi
  fi
fi

# error: invalid version
if [ -z $downloadURL ]; then
  echo -e "\ncould not detect \"Build Version\" from variable: \"${verStr}\".\nsee at:\n" 1>&2
  echo "  http://www.oracle.com/technetwork/java/javase/downloads/" 1>&2
  exit 1
fi

# create working directory
[ -e $workDir ] || mkdir -p $workDir

# detect to installed JDK
echo -e "\nChecking installed JDK ..."

# RPM
finder=($(rpm -qa 2>&1 | grep -E "^jdk" | grep -E "\.x86_64" | sort | cut -d '-' -f 1,2)) && \
for found in "${finder[@]}"; do
  [ ! -z $found ] || continue
  if javaHome=`rpm -ql $found | grep -E "\/bin\/java$" | grep -v -E "\/jre\/bin\/java$"`; then
    if installedVer=`"${javaHome}" -version 2>&1 | grep -i -E "java version" | cut -d '"' -f 2`; then
      if [ "${#javaHomes[@]}" -gt 0 ]; then
        echo " ${javaHomes[@]} " | grep " ${javaHome} " >/dev/null && continue
        javaHomes=("${javaHomes[@]}" $javaHome)
      else
        javaHomes=($javaHome)
      fi
      [ $ver -gt 7 ] && [[ $found =~ ^jdk[^\-] ]] && continue
      if [ "${#conflicts[@]}" -gt 0 ]; then
        echo " ${conflicts[@]} " | grep " ${javaHome} " >/dev/null && continue
        conflicts=("${conflicts[@]}" $javaHome)
      else
        conflicts=($javaHome)
      fi
      echo -n "  JDK$(echo $installedVer | sed -e 's/^1\.//' | sed -e 's/\.0_/u/' | sed -e 's/\.0$//') "
      echo -n "has installed in "
      echo -en "\"`echo $javaHome | sed -e 's/\/bin\/java$//'`\" "
      echo -e "(package \"$(echo $found | cut -d '-' -f 1)\")."
    elif [ -z $javaHome ]; then
      echo -en "  package named as \"${found}\" has installed, but "
      echo -e "\"`echo $javaHome | sed -e 's/\/bin\/java$//'`\" has collapsed."
    else
      yum remove -y -q $found --disablerepo=* 2>/dev/null && \
      echo -e "  broken package named as \"${found}\" removed."
    fi
  else
    echo -e "  package named as \"${found}\" has installed, but could not find \"bin/java\"."
  fi
done

# alternatives
finder=($(alternatives --display java 2>&1 | grep -e "\/bin\/java -" | grep -v openjdk | grep -v -E "\/jre(1\.[0-9]\.0(_[0-9]+)?)?\/bin\/java" | sort | sed -e 's/\-.*$//')) && \
for found in "${finder[@]}"; do
  [ ! -z $found ] || continue
  [ -L $found ] && found=`readlink -m "${found}"`
  if [ -e $found ] && \
     installedVer=`"${found}" -version 2>&1 | grep -i -E "java version" | cut -d '"' -f 2`; then
    if [ "${#javaHomes[@]}" -gt 0 ]; then
      echo " ${javaHomes[@]} " | grep " ${found} " >/dev/null && continue
      javaHomes=("${javaHomes[@]}" $found)
    else
      javaHomes=($found)
    fi
    echo -n "  JDK$(echo $installedVer | sed -e 's/^1\.//' | sed -e 's/\.0_/u/' | sed -e 's/\.0$//') "
    echo -n "has installed in "
    echo -e "\"$(echo $found | sed -e 's/\/bin\/java$//')\" (alternatives)."
  else
    alternatives --remove java $found 1>/dev/null 2>&1 && \
    echo -e "  broken alternative path: \"${found}\" has removed."
  fi
done

finder=($(alternatives --display java 2>&1 | grep -e "\/bin\/java -" | grep -v openjdk | sort | sed -e 's/\-.*$//')) && \
if [ "${#finder[@]}" -gt 0 ] && \
   ! readlink -e /etc/alternatives/java > /dev/null; then
   alternatives --auto java 1>/dev/null 2>&1
   echo -e "  repare alternatives for java: \"`readlink -m /etc/alternatives/java`\"."
fi

# install directory (default: /usr/java)
finder=($(ls -L $jdkDir 2>&1 | grep -e "^jdk" | sort)) && \
for found in "${finder[@]}"; do
  [ ! -z $found ] || continue
  found="${jdkDir}/${found}/bin/java"
  if javaHome=`readlink -e "${found}"`; then
    if installedVer=`$javaHome -version 2>&1 | grep -i -E "java version" | cut -d '"' -f 2`; then
      if [ "${#javaHomes[@]}" -gt 0 ]; then
        echo " ${javaHomes[@]} " | grep " ${javaHome} " >/dev/null && continue
        javaHomes=("${javaHomes[@]}" $javaHome)
      else
        javaHomes=($javaHome)
      fi
      echo -n "  JDK$(echo $installedVer | sed -e 's/^1\.//' | sed -e 's/\.0_/u/' | sed -e 's/\.0$//') "
      echo -n "has installed in "
      echo -e "\"`echo $javaHome | sed -e 's/\/bin\/java$//'`\" (not managed)."
    else
      echo -en "  found directory \"${found}\" \"${jdkDir}\", but "
      echo -e "\"${javaHome}\" has collapsed."
    fi
  else
    echo -e "  found directory \"${found}\" \"${jdkDir}\", but could not find \"bin/java\"."
  fi
done

# already installed
[ "${#javaHomes[@]}" -gt 0 ] && \
for javaHome in "${javaHomes[@]}"; do
  [ ! -z $downloadURL ] || break
  if $javaHome -version 2>&1 | grep -i -E "java version" | grep $installVer > /dev/null; then
    downloadURL=
    echo -en "\n  JDK ${nameOfVer} already installed in "
    echo -e "\"$(echo $javaHome | sed -e 's/\/bin\/java$//')\"."
    break
  fi
done

# escape previous version of JDK
if [ ! -z $downloadURL ] && [ "${#conflicts[@]}" -gt 0 ]; then
  echo -e "\nCheck duplicates ..."
  finder=()
  for conflict in "${conflicts[@]}"; do
    [ -n $conflict ] || continue
    conflictJDK=`echo $conflict | sed -e 's/\/bin\/java//'`
    [ "${#finder[@]}" -gt 0 ] && echo " ${finder[@]} " | grep " ${conflictJDK} " >/dev/null && continue
    conflictFVer=`$conflict -version 2>&1 | grep -i -E "java version" | cut -d '"' -f 2` || continue
    conflictVer=`echo $conflictFVer | cut -d '.' -f 2`
    [ $((ver)) -gt 7 ] && continue
    [ $((conflictVer)) -gt 7 ] && continue
    echo $conflictFVer | grep _ >/dev/null && conflictUVer=`echo $conflictFVer | cut -d '_' -f 2`
    [ -n $conflictUVer ] || conflictUVer=0
    if [ $((conflictVer)) -gt $ver ]; then
      [[ "${downloadURL}" =~ \.tar\.gz$ ]] && continue
      echo "  newer version of JDK has installed."
      downloadURL=`echo $downloadURL | sed -e 's/\-rpm//' | sed -e 's/\.rpm$/.tar.gz/'`
    elif [ $((conflictVer)) -lt $ver ]; then
      echo "  previous version of JDK has installed."
      if [ "${#finder[@]}" -gt 0 ]; then
        finder=("${#finder[@]}" "${conflictJDK}")
      else
        finder=("${conflictJDK}")
      fi
    elif [ $((conflictUVer)) -gt $updateVer ]; then
      [[ "${downloadURL}" =~ \.tar\.gz$ ]] && continue
      echo "  newly updated version of JDK ${ver} has installed."
      downloadURL=`echo $downloadURL | sed -e 's/\-rpm//' | sed -e 's/\.rpm$/.tar.gz/'`
    elif [ $((conflictUVer)) -lt $updateVer ]; then
      echo "  previous updated version of JDK ${ver} has installed."
      if [ "${#finder[@]}" -gt 0 ]; then
        finder=("${#finder[@]}" "${conflictJDK}")
      else
        finder=("${conflictJDK}")
      fi
    else
      continue
    fi
  done

  if [ "${#finder[@]}" -gt 0 ]; then
    echo -n "  escaping previous version(s) "
    for found in "${finder[@]}"; do
      readlink -e $found >/dev/null || continue
      cp -pR $found $workDir/. >/dev/null
      echo -n "."
    done
    echo -n "."
    currentDir=`pwd`
    cd "${workDir}"
    tar zcf stealth.jdk.tar.gz jdk* 1>/dev/null 2>&1
    cd "${currentDir}"
    echo -en "\n"
  fi
fi

# download
if [ ! -z $downloadURL ]; then
  downloadSource=$((echo $downloadURL) | sed -e 's/.*\///')
  echo -e "\nDownloading JDK ${nameOfVer} (${downloadSource}) ..."
  curl -fjkL -# $downloadURL \
   -H "Cookie: oraclelicense=accept-securebackup-cookie" \
   -o $workDir/$downloadSource

  if [ ! -e $workDir/$downloadSource ]; then
    echo -e "\ncould not download JDK ${nameOfVer} (${downloadSource}),\ncheck the version at:"
    echo "http://www.oracle.com/technetwork/java/javase/downloads/"
    exit 1
  elif [[ "${downloadSource}" =~ \.bin$ ]]; then
    chmod +x $workDir/$downloadSource
    sed -i 's/agreed=/agreed=1/g' $workDir/$downloadSource
    sed -i 's/more <<"EOF"/cat <<"EOF"/g' $workDir/$downloadSource
    currentDir=`pwd`
    cd "${workDir}"
    if [[ "${downloadSource}" =~ rpm\.bin$ ]]; then
      echo "yes" | $workDir/$downloadSource -x 1>/dev/null 2>&1
      downloadSource=$(echo $(unzip -l $workDir/$downloadSource 2>/dev/null | grep jdk | grep -e "rpm$" | sed -e 's/.*\s//') 2>&1)
    else
      echo "yes" | $workDir/$downloadSource 1>/dev/null 2>&1
    fi
    cd "${currentDir}"
    downloadSource=jdk${installVer}
  elif [[ "${downloadSource}" =~ \.tar\.gz$ ]]; then
    tar zxf $workDir/$downloadSource -C $workDir
    downloadSource=jdk${installVer}
  fi

  if [ ! -e $workDir/$downloadSource ]; then
    echo -e "\ncould not download JDK ${nameOfVer} (${downloadSource})."
    exit 1
  else
    echo -e "\n  Installing JDK ${nameOfVer} ..."
  fi

  if [[ "${downloadSource}" =~ \.rpm$ ]]; then
    yum install -y -q $workDir/$downloadSource 1>/dev/null 2>&1
  elif [ -d $workDir/$downloadSource ]; then
    cp -pR $workDir/$downloadSource $jdkDir/$downloadSource
  fi

  if [ -d $jdkDir/jdk$installVer ]; then  
    echo -e "\n  JDK ${nameOfVer} installed in \"${jdkDir}/jdk${installVer}\"."
    if [ "${#javaHomes[@]}" -gt 0 ]; then
      javaHomes=("${javaHomes[@]}" "${jdkDir}/jdk${installVer}/bin/java")
    else
      javaHomes=("${jdkDir}/jdk${installVer}/bin/java")
    fi
  else
    echo "[${$jdkDir}/jdk${installVer}]"
    echo -e "\n  JDK ${nameOfVer} (${downloadSource}) install failed."
    exit 1
  fi

  if [ -e $workDir/stealth.jdk.tar.gz ]; then
    echo -e "\n  restoring previous version(s) ..."
    tar zxf $workDir/stealth.jdk.tar.gz -C $jdkDir
  fi
fi

if [ "${#javaHomes[@]}" -gt 0 ]; then
  for javaHome in "${javaHomes[@]}"; do
    installed=`$javaHome -version 2>&1 | grep -E "java version" | cut -d '"' -f 2` || continue
    installedVer=$(echo $installed | cut -d '.' -f 2) || continue
    if [ $((installedVer)) -gt 6 ]; then
      mavenVer=3.3.9
    elif [ $((installedVer)) -gt 5 ]; then
      mavenVer=3.2.5
    elif [ $((installedVer)) -eq 5 ]; then
      mavenVer=2.2.1
    else
      mavenVer=
    fi
    [ ! -z $mavenVer ] || continue
    curl -fLs "${scriptURL}jdk.${installedVer}.alternatives.sh" \
     -o ${workDir}/jdk.${installedVer}.alternatives.sh
    [ -e ${workDir}/jdk.${installedVer}.alternatives.sh ] || continue
    if $maven; then
      [ -e $mavenDir ] || mkdir $mavenDir
      mavenSource=$(echo $mavenSourceBase | sed -e "s/@mavenVer/${mavenVer}/")
      [ ! -z $mavenSource ] || continue
      if [ ! -e ${mavenDir}/${mavenSource} ]; then 
        mavenSourceURL=$(echo $mavenBaseURL | sed -e "s/@mavenVer/${mavenVer}/g")${mavenSource}-bin.tar.gz
        echo -e "\n  Downloading Apache Maven ${mavenVer} ..."
        [[ "${mavenVer}" =~ ^3 ]] || \
          mavenSourceURL=$(echo $mavenSourceURL | sed -e 's/www/archive/' | sed -e "s/\/maven-3\/${mavenVer}//")
        curl -fjkL -# $mavenSourceURL \
         -o ${workDir}/${mavenSource}-bin.tar.gz
        if [ -e ${workDir}/${mavenSource}-bin.tar.gz ]; then
          tar zxf ${workDir}/${mavenSource}-bin.tar.gz -C $mavenDir >/dev/null 2>&1
          echo -e "\n  Maven ${mavenVer} installed in \"${mavenDir}/${mavenSource}\"."
        else
          echo -e "\n  ${mavenSource} download failed."
        fi
      fi

      if [ -e $mavenDir/$mavenSource ]; then
        sed -i -e '$s/.*/\0 \\/' $workDir/jdk.$installedVer.alternatives.sh
        cat << _EOT_ >> $workDir/jdk.$installedVer.alternatives.sh
 --slave /usr/bin/mvn mvn ${mavenDir}/${mavenSource}/bin/mvn \\
 --slave /usr/bin/mvnDebug mvnDebug ${mavenDir}/${mavenSource}/bin/mvnDebug

_EOT_
      fi
    fi

    $embed || echo -e "\nSet Environment \$JAVA_HOME (relate to alternatives config)."

    chmod +x $workDir/jdk.$installedVer.alternatives.sh
    $workDir/jdk.$installedVer.alternatives.sh \
    $installed $(echo $installed | sed -e 's/\.0$/.0_00/' | sed -e 's/[\._]//g') 1>/dev/null 2>&1
    echo -e "  set alternatives for \"java\" (${javaHome}) ..."
    $embed && continue

    cat <<_EOT_ > /etc/profile.d/java.sh
#/etc/profile.d/java.sh

# Set Environment with alternatives for Java VM.
export JAVA_HOME=\$(readlink /etc/alternatives/java | sed -e 's/\/bin\/java//g')

_EOT_
     $maven && cat <<_EOT_ >> /etc/profile.d/java.sh
# Set Environment with alternatives for Apache Maven.
[ -e /usr/bin/mvn ] && export M2=\$(readlink -m \$(which mvn))
[ -n "\${M2}" ] && export M2_HOME=\$(echo \$M2 | sed -e 's/\/bin\/mvn$//g')

_EOT_
    embed=true
  done
fi

if [ -e $jdkDir/jdk$installVer ]; then
  if [ -n "${downloadSource}" ]; then
    echo -e "\nNow complete to setting JDK ${nameOfVer}."
  else
    echo -e "\nNow complete to setting alternatives for JDK ${nameOfVer}."
  fi
  alternatives --set java $jdkDir/jdk$installVer/bin/java
  [ -e /etc/profile.d/java.sh ] && source /etc/profile.d/java.sh
  echo -e "$((echo "`java -version 2>&1`") | sed -e 's/^./    \0/')"
  [ $JAVA_HOME ] && \
  [ $($JAVA_HOME/bin/java -version 2>&1 | grep -e "java version" | wc -l) -gt 0 ] && \
   echo -e "    JAVA_HOME: ${JAVA_HOME}"

  if [ -e /etc/alternatives/java ]; then
    echo -e "\n  alternatives for java:"
    echo -e "$((echo "`alternatives --display java | grep -e "^\/usr\/java/.*\/bin\/java"`") | sort | sed -e 's/^./    \0/')"
  fi
  if [ -e /etc/profile.d/java.sh ]; then
    echo -e "\n  usage:\n    alternatives --config java && source /etc/profile"
    echo "     - or -"
    echo -e "    alternatives --set java ${jdkDir}/jdk${installVer}/bin/java && \ \n     source /etc/profile"
  fi
  $maven && \
    echo -e "\n  Maven:\n$((echo "`mvn -version 2>&1`") | sed -e 's/^./    \0/')"
else
  echo -e "\n  Install JDK ${nameOfVer} failed."
  [ $(`which java 2>/dev/null` -version 2>&1 | grep -e "java version" | wc -l) -gt 0 ] && \
   echo -e "$((echo "`java -version 2>&1`") | sed -e 's/^./  \0/')"
  [ $JAVA_HOME ] && [ `$JAVA_HOME/bin/java -version >/dev/null 2>&1` ] && \
   echo -e "  JAVA_HOME: ${JAVA_HOME}"
  exit 1
fi

echo -e "\n  cleanup ..."
rm -rf $workDir >/dev/null 2>&1
echo -e "\n  Done."

exit 0
