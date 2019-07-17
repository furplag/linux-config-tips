#! /bin/bash
set -ue -o pipefail
export LC_ALL=C
###
# gcp.init.config.sh
# https://github.com/furplag/linux-config-tips
# Copyright 2019+ furplag
# Licensed under MIT (https://github.com/furplag/linux-config-tips/blob/master/LICENSE)
# More, easily create virtual machines for development, and disposable .
# + Set Locale.
# + Set Timezone.
# + Unforcing SELinux.
# + Change SSH port number for protect under crack.
#  - enable to login as Root directly.
#  - Only use Public Key Authentication.
#  - tweak Firewalld.
#  - generate SSH key pair.
# + tweak YUM.
#  - enable to use City-fan.org.
#  - enable to use IUS.
#  - enable to use Remi.
# + ready to use some of necessary packages.

###
# get metadata
#
# priority: instance, project .
# @param $key key of attribute
# @return metadata value
get_meta() {
  declare -r meta_project_url=http://metadata.google.internal/computeMetadata/v1/project
  declare -r meta_instance_url=http://metadata.google.internal/computeMetadata/v1/instance
  declare -r meta_header="Metadata-Flavor: Google"
  declare -r key=${$0:-'not.exists.'}
  value=`curl "${meta_instance_url}/attributes/${key}?alt=text" -H "${meta_header}" -fs`
  value=${value:-$(curl "${meta_project_url}/attributes/${key}?alt=text" -H "${meta_header}" -fs)}

  echo "${value}"
}

###
# variables
declare locale=$(get_meta lang)
[[ $locale ] = "" ] && ${locale:=ja_JP.UTF-8}

declare timezone=$(get_meta timezone)
[[ $timezone ] = "" ] && ${timezone:=Asia/Tokyo}




declare -r port_number_meta=`curl "${meta_url}/attributes/ssh-port?alt=text" -H "Metadata-Flavor: Google" -fs`
declare -r port_number=${port_number_meta:-22522}
declare -r passphrase_meta=`curl "${meta_url}/attributes/ssh-passphrase?alt=text" -H "Metadata-Flavor: Google" -fs`
declare -r passphrase=${passphrase_meta:-cheLsea0x0}

