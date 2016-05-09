#!/bin/sh
set -ue -o pipefail
export LC_ALL=C

# variables
declare -r name=`basename $0`
declare -r javaHomeDefault=/usr/java/default
declare javaHome=
declare quietly=false
declare version=
declare -i ver=

# Usage
usage(){
  cat << _EOT_
${name}

Description:
  1. Set "alternatives" for JDK.
Requirement:
  1. root user executable only.
  2. Installable JDK version: 5 - 8.
usgae: ${name} [-d javaHome] [-q]
  -d : javaHome (optional, default: $javaHomeDefault)
       absolute path of java ( e.g. /usr/java/jdk1.8.0_92) .
  -q : running quietly.
_EOT_
}

while getopts dq: OPT; do
  case $OPT in
    d) javaHome=${OPTARG:-${javaHomeDefault}};;
    q) quietly=true;;
    h) usage; exit 1;;
    \?) usage; exit 1;;
  esac
done

if [ -z "${javaHome}" ]; then
  [ $quietly ] || usage
  exit 1
elif [ ! -e $javaHome ]; then
  [ $quietly ] || echo -e "\n  \"${javaHome}\" is not Java home."
  exit 1
fi

version=$($javaHome/bin/java -version 2>&1 | grep -i version | cut -d '"' -f 2)
if [ -z "${version}" ]; then
  [ $quietly ] || echo -e "\n  \"${javaHome}\" is not Java home."
  exit 1
fi

ver=$(echo $version | cut -d '.' -f 2)

if [ $ver -eq 0 ]; then
  [ $quietly ] || echo -e "\n  \"${javaHome}\" is not Java home."
  exit 1
fi

echo "[${javaHome}]"
echo "[${version}]"
echo "[${ver}]"

exit 0
