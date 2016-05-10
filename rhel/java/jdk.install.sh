#!/bin/sh
set -ue -o pipefail
export LC_ALL=C

# variables
declare -r name=`basename $0`
declare -r datetime=`date +"%Y%m%d%H%M%S"`
declare -r jdkDir=/usr/java
declare -r workDir=$jdkDir/quickstart/$datetime
declare -r baseURL=https://edelivery.oracle.com/otn-pub/java/jdk/
declare -r defaultVer=8u92-b14
declare verStr=
declare nameOfVer=
declare -i ver=
declare -i updateVer=
declare -i buildVer=
declare -r mavenDir=/usr/maven
declare -r mavenBaseURL=https://www.apache.org/dist/maven/maven-3/@mavenVer/binaries/
declare -r mavenSourceBase=apache-maven-@mavenVer
declare maven=false
declare mavenVer=
declare mavenSource=
declare downloadURL=
declare downloadSource=
declare conflictVer=
declare installSource=
declare -r scriptURL=https://raw.githubusercontent.com/furplag/linux-config-tips/master/rhel/java/
declare embed=false

# Usage
usage(){
  cat << _EOT_
${name}

Description:
  1. Install Oracle JDK.
  2. Does not remove previous version of JDK, if "yum update jdk" runs.
  3. Set "alternatives" for JDK.
  4. Set \$JAVA_HOME (relate to alternatives config).
  5. Install Apache Maven as java alternatives slaves (optional) .
Requirement:
  1. root user executable only.
  2. Installable JDK version: 5 - 8.
usgae: ${name} [-v jdkVersion] [-m]
  -v : jdkVersion (optional, default : 8u92-b14)
       (1.)[version]
         5 : 5u22
         6 : 6u45-b06
         7 : 7u80-b15
         8 : 8u92-b14
       (1.)[version].0_[updateVersion](-b[build])
       [version]u[updateVersion]-b[build]
  -m : install maven (optional, default : false)
       JDK 5 : maven-2.2.1
       JDK 6 : maven-3.2.5
       JDK 7 : maven-3.3.9
       JDK 8 : maven-3.3.9
_EOT_
}

if [ ! ${EUID:-${UID}} = 0 ]; then usage; echo -e "\nPermission Denied, Root user only.\nHint: sudo ${0}"; exit 1; fi

while getopts hmv: OPT; do
  case $OPT in
    v) verStr=${OPTARG:-${defaultVer}};;
    m) maven=true;;
    h) usage; exit 1;;
    \?) usage; exit 1;;
  esac
done

[ -n "${verStr}" ] || verStr=$defaultVer

if [[ $verStr =~ ^(1\.)?[5-9]u[0-9]{1,2}(\-b[0-9]{1,2})?$ ]];then
  nameOfVer=$(echo $verStr | sed -e 's/^1\.//')
elif [[ $verStr =~ ^(1\.)?[5-9]\.0_[0-9]{1,2}(\-b[0-9]{1,2})?$ ]]; then
  nameOfVer=$(echo $verStr | sed -e 's/^1\.//' | sed -e 's/\.0_/u/')
elif [[ $verStr =~ ^(1\.)?[5-9]$ ]]; then
  ver=$(echo $verStr | sed -e 's/^1\.//')
  case $ver in
    5) nameOfVer=5u22;;
    6) nameOfVer=6u45-b06;;
    7) nameOfVer=7u80-b15;;
    8) nameOfVer=8u92-b14;;
  esac
else
  usage; exit 1
fi

ver=$(echo $nameOfVer | sed -e 's/u.*//')
updateVer=$(echo $nameOfVer | sed -e 's/.*u//' | sed -e 's/-.*//')

if [ $(echo $nameOfVer | grep b | wc -l) -gt 0 ]; then
  buildVer=$(echo $nameOfVer | sed -e 's/.*b//')
fi

if [ $((ver)) -gt 5 ] && [ $(($buildVer)) -eq 0 ]; then
  if [ $((ver)) -eq 6 ] && [ $((updateVer)) -gt 3 ]; then
    usage; echo -e "\n  could not detect \"Build Version\" from variable: \"${verStr}\"."; exit 1
  elif [ $((ver)) -gt 6 ]; then
    usage; echo -e "\n  could not detect \"Build Version\" from variable: \"${verStr}\"."; exit 1
  fi
fi

echo -e "\n  Checking installed java ..."

jdkVers=()
[ $((rpm -qa 2>&1) | grep -e "jdk*" | grep -v -e "openjdk*" | grep x86_64 | wc -l) -gt 0 ] && \
 for j in $((rpm -qa 2>&1) | sort | grep -e "jdk*" | grep -v -e "openjdk*" | grep x86_64 | cut -d '-' -f 1,2); do
   packageName=$(echo $j | cut -d '-' -f 1)
   jdkVer=$(echo $j | cut -d '-' -f 2)
   echo -e "    ${jdkVer} has installed as \"${packageName}\" (managed package)"
   if [ "${#jdkVers[@]}" -gt 0 ]; then
     [ $((echo "${jdkVers[*]}" | grep $jdkVer) | wc -l) -gt 0 ] || \
      jdkVers=("${jdkVers[@]}" $jdkVer)
   else
     jdkVers=($jdkVer)
   fi
   [ $(($ver)) -gt 7 ] || [ $packageName != "jdk" ] || conflictVer=$jdkVer
 done

[ $((alternatives --display java 2>&1) | grep -e "\/bin\/java -" | grep -v -e "openjdk*" | wc -l) -gt 0 ] && \
 for j in $((alternatives --display java 2>&1) | sort | grep -e "\/bin\/java -" | grep -v -e "openjdk*" | sed -e 's/ -.*//'); do
   if [ ! -e $j ]; then
     alternatives --remove java $j 2>/dev/null && \
     echo -e "    broken alternative path: \"${j}\" has removed."
     continue
   fi
   jdkVer=$(($j -version 2>&1) | grep -i version | cut -d '"' -f 2)
   if [ "${#jdkVers[@]}" -gt 0 ] && [ $((echo "${jdkVers[*]}" | grep $jdkVer) | wc -l) -gt 0 ]; then
     continue
   elif [ "${#jdkVers[@]}" -gt 0 ]; then
     echo -e "    ${jdkVer} has install in \"$(echo $j | cut -d '-' -f 1)\" (alternatives)."
     jdkVers=("${jdkVers[@]}" $jdkVer)
   else
     jdkVers=($jdkVer)
   fi
 done

if [ $((alternatives --display java 2>&1) | grep -e "\/bin\/java -" | grep -v -e "openjdk*" | wc -l) -gt 0 ] && \
   [ ! `readlink -e /etc/alternatives/java` ]; then
   alternatives --auto java
   echo -e "\n    repare alternatives for java: \"$(echo `readlink -m /etc/alternatives/java`)\"."
fi

[ $((ls -L $jdkDir 2>&1) | grep -e "^jdk" | wc -l) -gt 0 ] && \
 for j in $((ls -L $jdkDir 2>&1) | grep -e "^jdk" | sort); do
   jdkVer=$($jdkDir/$j/bin/java -version 2>&1 | grep -i version | cut -d '"' -f 2)
   if [ "${#jdkVers[@]}" -gt 0 ] && [ $((echo "${jdkVers[*]}" | grep $jdkVer) | wc -l) -gt 0 ]; then
     continue
   elif [ "${#jdkVers[@]}" -gt 0 ]; then
     echo -e "    ${jdkVer} has installed in \"$(echo $j | cut -d '-' -f 1)\" (not managed)."
     jdkVers=("${jdkVers[@]}" $jdkVer)
   else
     jdkVers=($jdkVer)
   fi
 done

if [ "${#jdkVers[@]}" -gt 0 ] && [ $((echo "${jdkVers[*]}" | grep "1.${ver}.0_${updateVer}") | wc -l) -gt 0 ]; then
  echo -e "\n  JDK ${nameOfVer} already installed."
  installSource=jdk1.${ver}.0_${updateVer}
elif [ $(($ver)) -lt 6 ]; then
  downloadURL="${baseURL}/1.${ver}.0_${updateVer}/jdk-1_${ver}_0_${updateVer}-linux-amd64-rpm.bin"
elif [ $(($buildVer)) -eq 0 ]; then
  downloadURL="${baseURL}/${ver}u${updateVer}/jdk-${ver}u${updateVer}-linux-amd64-rpm.bin"
elif [ $(($ver)) -eq 6 ]; then
  downloadURL="${baseURL}/${nameOfVer}/jdk-${ver}u${updateVer}-linux-x64-rpm.bin"
else
  downloadURL="${baseURL}/${nameOfVer}/jdk-${ver}u${updateVer}-linux-x64.rpm"
fi

[ -e $workDir ] || mkdir -p $workDir

if [ $downloadURL ]; then
  if [ $conflictVer ]; then
    installedVer=$((echo $conflictVer) | cut -d '.' -f 2)
    if [ $(($ver)) -gt $installedVer ]; then
      echo -e "\n    escaping previous version ..."
      tar zcf $workDir/stealth.jdk.tar.gz $jdkDir/jdk1.[0-$(($ver-1))]* >/dev/null 2>&1
    elif [ $(($ver)) -lt $installedVer ]; then
      echo -e "\n    newer version of JDK has installed."
      downloadURL=$((echo $downloadURL) | sed -e 's/-rpm//' | sed -e 's/\.rpm$/.tar.gz/')
    elif [ $(($updateVer)) -gt $((echo $conflictVer) | cut -d '_' -f 2) ]; then
      echo -e "\n    previous updated version of JDK ${ver} has installed.\n    escaping previous version ..."
      tar zcf $workDir/stealth.jdk.tar.gz $jdkDir/jdk1.$ver.0_[0-$(($updateVer-1))]* >/dev/null 2>&1
    elif [ $(($updateVer)) -lt $((echo $conflictVer) | cut -d '_' -f 2) ]; then
      echo -e "\n    newly updated version of JDK ${ver} has installed."
      downloadURL=$((echo $downloadURL) | sed -e 's/-rpm//' | sed -e 's/\.rpm$/.tar.gz/')
    fi
  fi

  downloadSource=$((echo $downloadURL) | sed -e 's/.*\///')
  echo -e "\n  Downloading JDK ${nameOfVer} (${downloadSource}) ..."
  curl -fjkL -# $downloadURL \
   -H "Cookie: oraclelicense=accept-securebackup-cookie" \
   -o $workDir/$downloadSource

  if [ ! -e $workDir/$downloadSource ]; then
    echo -e "\n  JDK ${nameOfVer} (${downloadSource}) download failed."
    exit 1
  elif [[ "${downloadSource}" =~ \.bin$ ]]; then
    chmod +x $workDir/$downloadSource
    sed -i 's/agreed=/agreed=1/g' $workDir/$downloadSource
    sed -i 's/more <<"EOF"/cat <<"EOF"/g' $workDir/$downloadSource
    currentDir=`pwd`
    cd "${workDir}"
    if [[ "${downloadURL}" =~ rpm\.bin$ ]]; then
      $workDir/$downloadSource -x >/dev/null 2>&1
      installSource=$(echo $(unzip -l $workDir/$downloadSource 2>/dev/null | grep jdk | grep -e "rpm$" | sed -e 's/.*\s//') 2>&1)
    else
      $workDir/$downloadSource >/dev/null 2>&1
      installSource=$(echo $(unzip -l $workDir/$downloadSource 2>/dev/null | grep jdk | grep -e "_${updateVer}\/$" | sed -e 's/.*\s//' | sed -e 's/\/$//') 2>&1)
    fi
    cd "${currentDir}"
  elif [[ "${downloadSource}" =~ \.tar\.gz$ ]]; then
    tar zxf $workDir/$downloadSource -C $workDir
    installSource=$(tar ztf $workDir/$downloadSource | grep -e "_${updateVer}\/$" | sed -e "s/\/$//")
  fi

  if [ -n "${workDir}" ] && [ -n "${installSource}" ] && [ -d $workDir/$installSource ]; then
    echo -e "\n  Installing JDK ${nameOfVer} ..."
    if [ -d $workDir/$installSource ]; then
      cp -pR $workDir/$installSource $jdkDir/$installSource
    fi
  elif [[ "${downloadSource}" =~ \.rpm$ ]]; then
    echo -e "\n  Installing JDK ${nameOfVer} ..."
    yum install -y $workDir/$downloadSource >/dev/null 2>&1
    installSource=jdk1.$ver.0_$updateVer
  elif [[ "${installSource}" =~ \.rpm$ ]]; then
    echo -e "\n  Installing JDK ${nameOfVer} ..."
    yum install -y $workDir/$installSource >/dev/null 2>&1
    installSource=jdk1.$ver.0_$updateVer
  fi

  if [ -n "${jdkDir}" ] && [ -n "${installSource}" ] && [ -e $jdkDir/$installSource ]; then
    echo -e "\n  JDK ${nameOfVer} installed in \"${jdkDir}/jdk1.${ver}.0_${updateVer}\"."
    if [ "${#jdkVers[@]}" -gt 0 ]; then
      jdkVers=("${jdkVers[@]}" "1.${ver}.0_${updateVer}")
    else
      jdkVers=("1.${ver}.0_${updateVer}")
    fi
  else
    echo -e "\n  JDK ${nameOfVer} (${downloadSource}) install failed."
    exit 1
  fi
fi

if [ -e $workDir/stealth.jdk.tar.gz ]; then
  echo -e "\n  restoring previous version ..."
  tar zxf $workDir/stealth.jdk.tar.gz -C $jdkDir --strip=$(echo "$jdkDir" | sed -e 's/^\///' | sed -e 's/\//\n/g' | wc -l)
fi

if [ $installSource ]; then
  for jdkVer in "${jdkVers[@]}"; do
    jVer=$(echo $jdkVer | cut -d '.' -f 2)
    if [ $((jVer)) -gt 6 ]; then
      mavenVer=3.3.9
    elif [ $((jVer)) -gt 5 ]; then
      mavenVer=3.2.5
    elif [ $((jVer)) -eq 5 ]; then
      mavenVer=2.2.1
    else
      mavenVer=
    fi
    [ -n "${mavenVer}" ] || continue
    curl -fLs "${scriptURL}jdk.${jVer}.alternatives.sh" \
     -o ${workDir}/jdk.${jVer}.alternatives.sh
    [ $? ] || continue
    if $maven; then
      [ -e $mavenDir ] || mkdir $mavenDir
      mavenSource=$(echo $mavenSourceBase | sed -e "s/@mavenVer/${mavenVer}/")
      if [ ! -e ${mavenDir}/${mavenSource} ]; then 
        mavenSourceURL=$(echo $mavenBaseURL | sed -e "s/@mavenVer/${mavenVer}/g")${mavenSource}-bin.tar.gz
        echo -e "\n  Downloading Apache Maven ${mavenVer} ..."
        [[ "${mavenVer}" =~ ^3 ]] || \
         mavenSourceURL=$(echo $mavenSourceURL | sed -e 's/www/archive/' | sed -e "s/\/maven-3\/${mavenVer}//")
        curl -fjkL -# $mavenSourceURL \
         -o ${workDir}/${mavenSource}-bin.tar.gz
        if [ -e ${workDir}/${mavenSource}-bin.tar.gz ]; then
          tar zxf ${workDir}/${mavenSource}-bin.tar.gz -C $mavenDir >/dev/null 2>&1
        else
          echo -e "\n  ${mavenSource} download failed."
        fi
      fi
      if [ -e ${mavenDir}/${mavenSource} ]; then
        sed -i -e '$s/.*/\0 \\/' $workDir/jdk.${jVer}.alternatives.sh
        cat << _EOT_ >> ${workDir}/jdk.${jVer}.alternatives.sh
 --slave /usr/bin/mvn mvn ${mavenDir}/${mavenSource}/bin/mvn \\
 --slave /usr/bin/mvnDebug mvnDebug ${mavenDir}/${mavenSource}/bin/mvnDebug

_EOT_
      fi
    fi
    chmod +x ${workDir}/jdk.${jVer}.alternatives.sh
    ${workDir}/jdk.${jVer}.alternatives.sh "${jdkVer}"
    if $embed; then continue; fi
    echo -e "\n  Set Environment \$JAVA_HOME (relate to alternatives config).\n"
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

if [ $jdkDir ] && [ $installSource ] && [ -e $jdkDir/$installSource ]; then
  if [ $downloadSource ]; then
    echo -e "\n  Now complete to setting JDK ${nameOfVer}."
  else
    echo -e "\n  Now complete to setting alternatives for JDK ${nameOfVer}."
  fi
  alternatives --set java $jdkDir/$installSource/bin/java
  [ -e /etc/profile.d/java.sh ] && source /etc/profile.d/java.sh
  echo -e "$((echo "`java -version 2>&1`") | sed -e 's/^./    \0/')"
  [ $JAVA_HOME ] && \
  [ $($JAVA_HOME/bin/java -version 2>&1 | grep -e "java version" | wc -l) -gt 0 ] && \
   echo -e "    JAVA_HOME: ${JAVA_HOME}"

  if [ -e /etc/alternatives/java ]; then
    echo -e "\n  alternatives for java:"
    echo -e "$((echo "`alternatives --display java | grep -e "^\/usr\/java/.*\/bin\/java"`") | sed -e 's/^./    \0/')"
  fi
  if [ -e /etc/profile.d/java.sh ]; then
    echo -e "\n  usage:\n    alternatives --config java && source /etc/profile"
    echo -e "     - or -"
    echo -e "    alternatives --set java ${jdkDir}/${installSource}/bin/java && \ \n     source /etc/profile"
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

exit 0
