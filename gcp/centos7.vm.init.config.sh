#! /bin/bash
set -ue -o pipefail
export LC_ALL=C

###
# centos7.vm.init.config.sh (GCP)
# https://github.com/furplag/linux-config-tips
# Copyright 2019+ furplag
# Licensed under MIT (https://github.com/furplag/linux-config-tips/blob/master/LICENSE)
#
# More, easily create virtual machines for development, and disposable .
#
# Startup script of Google Compute Engine, inject parameter using GCloud and GSUtil .
# 1. makes some optimizations for the VM to stands a web server .
#   1. i18N setting (localectl) .
#   2. l10N setting (timedatectl) .
#   3. unforcing SELinux .
#   4. makes ready to use some of necessary packages (city-fan, epel, ius, nginx, remi) .
# 2. change SSH port number for protect under crack .
#   1. SSH port number setting (sshd) .
#   2. only use Public Key Authentication .
#   3. Firewall setting (firewalld) .
#   4. generate SSH key pair .
# Prerequirement: add some metadatas before create VM instance .
#
# | Sccope | Key | Default value |
# ----|----|----
# | Project | lang | en_US.UTF-8 |
# | Project | time-zone |(no change Time Zone, if not specified the value of this key .)  |
# | Project / Instance | ssh-port |(no change SSH port number, if not specified the value of this key .) |
# | Project / Instance | ssh-passphrase |(no create SSH key pair, if not specified the value of this key .) |

###
# functions
###

###
# get metadata from GCP setting .
#
# @param scope of metadata, meant  instance or project .
# @param key of attribute
# @return metadata value
_compute_meta() {
  declare -r url_meta='http://metadata.google.internal/computeMetadata/v1'
  echo "$(curl "${url_meta}/${1:-'project'}/attributes/${2}?alt=text" -H "Metadata-Flavor: Google" -fs)"
}

###
# get metadata from GCP setting .
#
# priority: instance, project .
# @param key of attribute
# @return metadata value
_get_meta() {
  local key=${1:-'not.exists.'}
  local value=
  for scope in instance project; do
    : ${value:="$(_compute_meta ${scope} ${key})"}
    [[ ! ${value} = "" ]] && break
  done

  echo ${value:-"${2:-}"}
}

###
# just a shorthand .
#
# @param key of attribute
# @return whether we have to do, or not
_are_we_have_to_do() {
  if [[ "${1:-}" = "" ]] || \
  [[ ${#init_config_initialized[@]} -ne 0 && \
    "$(echo " ${init_config_initialized[@]} " | grep " ${1:-} " | wc -w)" -gt 0 ]]; then

    exit 1
  fi
  echo 0
}

###
# just a shorthand, add stamp for never do twice .
#
# @param operation name which done complete
_init_config_complete() {
  if [[ "${1:-}" = "" ]]; then
    exit 1
  elif [[ ${#init_config_initialized[@]} -lt 1 ]]; then
    init_config_initialized=("${init_config_initialized[@]+"${init_config_initialized[@]}"}" "${1}")
  elif [[ "$(echo " ${init_config_initialized[@]} " | grep " ${1:-} " | wc -w)" -lt 1 ]]; then
    init_config_initialized=("${init_config_initialized[@]}" "${1}")
  fi
}

###
# variables
###
declare -r locale=$(_get_meta lang en_US.UTF-8)
declare -r timezone=$(_get_meta timezone UTC)
declare -r ssh_port_number=$(_get_meta ssh-port)
declare -r ssh_passphrase=$(_get_meta ssh-passphrase)

# Create stamp .
[[ $(env | grep INIT_CONFIG_INITIALIZED | wc -w) -lt 1 ]] && export INIT_CONFIG_INITIALIZED=
[[ ! -e /etc/profile.d/init.config.initialized.sh ]] && \
  cat <<_EOT_> /etc/profile.d/init.config.initialized.sh
#/etc/profile.d/init.config.initialized.sh
export INIT_CONFIG_INITIALIZED=${INIT_CONFIG_INITIALIZED}
_EOT_

# DO NOT twice .
declare -a init_config_initialized=("$(cat /etc/profile.d/init.config.initialized.sh | grep INIT_CONFIG_INITIALIZED= | sed -e 's/^.*=//' -e 's/,/ /g' -e 's/ \+/ /g')")

# 1. makes some optimizations for the VM to stands a web server .

#   1. i18N setting (localectl) .
if [[ $(_are_we_have_to_do 'locale') ]]; then
  current_locale=$(localectl status | grep LANG= | sed -e 's/^.*LANG=\(.\+\)\s\?$/\1/')
  if [[ ! $locale = $current_locale ]]; then
    localectl set-locale LANG=${locale} && \
    echo -e " i18N: change system locale \"${current_locale}\" to \"${locale}\" ."
  else echo -e " i18N: system locale already set to \"${locale}\" ."
  fi
  _init_config_complete 'locale'
else echo -e " i18N: system locale already set to \"${locale}\" ."
fi

#   2. l10N setting (timedatectl) .
if [[ $(_are_we_have_to_do 'timezone') ]]; then
  current_timezone=$(timedatectl status | grep zone | sed -e 's/^.*zone: \+//' -e 's/ .*$//')
  if [[ ! $timezone = $current_timezone ]]; then
    timedatectl set-timezone "${timezone}" && \
    echo -e " l10N: change system Time Zone \"${current_timezone}\" to \"${timezone}\" ."
  else echo -e " l10N: system Time Zone already set to \"${timezone}\" ."
  fi
  _init_config_complete 'timezone'
else echo -e " l10N: system Time Zone already set to \"${timezone}\" ."
fi

#   3. unforcing SELinux .
[[ -e /etc/yum.repos.d/google-cloud.repo ]] && \
  sed -i -e 's/^repo_gpgcheck=1/repo_gpgcheck=0/g' /etc/yum.repos.d/google-cloud.repo

[[ $(yum list installed | grep policycoreutils-python | wc -l) -lt 1 ]] && \
  yum install -y policycoreutils-python

if [[ $(getenforce | grep -Eo "^P" | wc -l) -lt 1 ]]; then
  sed -i -e 's/^SELINUX=.*/#\0\nSELINUX=Permissive/' /etc/selinux/config && \
  echo " SELinux Unforced ."
else echo " SELinux running as Permissive, already .";
fi

#   4. makes ready to use some of necessary packages (city-fan, epel, ius, nginx, remi) .
if [[ $(_are_we_have_to_do 'packages') ]]; then
  [ ! -e /etc/yum.repos.d/city-fan.org.repo ] && \
    yum install -y http://www.city-fan.org/ftp/contrib/yum-repo/rhel7/x86_64/city-fan.org-release-2-1.rhel7.noarch.rpm
  [ ! -e /etc/yum.repos.d/epel.repo ] && \
    yum install -y epel-release
  [ ! -e /etc/yum.repos.d/ius.repo ] && \
    yum install -y https://repo.ius.io/ius-release-el7.rpm
  [ ! -e /etc/yum.repos.d/mariadb.repo ] && \
    cat <<_EOT_> /etc/yum.repos.d/mariadb.repo
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.4/centos7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
enabled=0
gpgcheck=1
_EOT_
  [ ! -e /etc/yum.repos.d/nginx.repo ] && \
    yum install -y http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
  [ ! -e /etc/yum.repos.d/pgdg.repo ] && \
    yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
  [ ! -e /etc/yum.repos.d/remi.repo ] && \
    yum install -y http://rpms.famillecollet.com/enterprise/remi-release-7.rpm

  sed -i -e 's/enabled=1/enabled=0/g' /etc/yum.repos.d/city-fan* /etc/yum.repos.d/epel* /etc/yum.repos.d/ius* /etc/yum.repos.d/mariadb* /etc/yum.repos.d/nginx* /etc/yum.repos.d/pgdg* /etc/yum.repos.d/remi* && \
  echo -e " makes ready to use some of necessary package repositories (city-fan, epel, ius, nginx, remi), remember add option \"--enablerepo=\" when use those ."

  yum --enablerepo=city-fan.org,epel install -y bind-utils certbot git libcurl yum-cron yum-utils && \
  sed -i -e 's/^apply_updates = yes/#\0\napply_updates = no/' \
    -e 's/^apply_updates = yes/#\0\napply_updates = no/' /etc/yum/yum-cron.conf && \
  echo -e " makes ready to use some of necessary packages (bind-utils, git, certbot, libcurl, yum-cron, yum-utils) ."
  _init_config_complete 'packages'
else echo -e " ready to use some of necessary packages and repos, already ."
fi

# 2. change SSH port number for protect under crack .
#   1. SSH port number setting (sshd) .
if [[ $(_are_we_have_to_do 'ssh-port') ]] && [[ ! "${ssh_port_number}" = "" ]]; then
  [[ $(semanage port -l | grep ssh_port_t | grep ${ssh_port_number} |wc -l) -lt 1 ]] && \
    setenforce 1 && \
    semanage port -a -t ssh_port_t -p tcp ${ssh_port_number} && \
    setenforce 0 && \
  echo -e " add port number \"${ssh_port_number}\" to SEManage ."

  #   3. Firewall setting (firewalld) .
  [[ ! -e /usr/lib/firewalld/services/ssh-tweaked.xml ]] && \
    cat /usr/lib/firewalld/services/ssh.xml > /usr/lib/firewalld/services/ssh-tweaked.xml

  sed -i -e "s@\(short>\).*\(<\/\)@\1SSH via $ssh_port_number\2@" \
    -e "s/port=\".*\"/port=\"$ssh_port_number\"/" /usr/lib/firewalld/services/ssh-tweaked.xml

  [[ $(systemctl status firewalld | grep -E "active \(running\)" | wc -l) -gt 0 ]] && \
    systemctl restart firewalld && \
    firewall-cmd --reload && \
    [[ $(firewall-cmd --list-service --zone=public | grep ssh-tweaked | wc -l) -lt 1 ]] && \
  echo -e " add tweaked SSH Service named as \"ssh-tweaked\" to Firewalld ."

  [[ $(systemctl status firewalld | grep -E "active \(running\)" | wc -l) -gt 0 ]] && \
    systemctl restart firewalld && \
    firewall-cmd --reload && \
    [ $(firewall-cmd --list-service --zone=public | grep ssh-tweaked | wc -l) -lt 1 ] && \
    firewall-cmd --add-service=ssh-tweaked --zone=public --permanent && \
    firewall-cmd --reload && \
  echo -e " accept TCP port number \"${ssh_port_number}\" on Firewalld ."

  #   2. only use Public Key Authentication .
  if [ $(cat /etc/ssh/sshd_config | grep -E "^Port ${ssh_port_number}" | wc -l) -lt 1 ]; then
    sed -i -e 's/^Port/#\0/' -e "s/^#Port/Port $ssh_port_number\n\0/" \
      -e 's/^#\?PermitRootLogin .*/PermitRootLogin without-password\n#\0/' \
      -e 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes\n#\0/' \
      -e 's/^#\?PasswordAuthentication .*/PasswordAuthentication no\n#\0/' \
      -e 's/^#\?PermitEmptyPasswords .*/PermitEmptyPasswords no\n#\0/' \
      -e 's/^#\?GSSAPIAuthentication .*/GSSAPIAuthentication no\n#\0/' \
      -e 's/^#\?GSSAPICleanupCredentials .*/GSSAPICleanupCredentials no\n#\0/' \
    /etc/ssh/sshd_config && \
    systemctl reload sshd && \
    echo -e " SSH daemon running with port number \"${ssh_port_number}\" ."

  else echo -e " SSH daemon running with port number \"${ssh_port_number}\", already ."
  fi
  _init_config_complete 'ssh-port'
fi

#   4. generate SSH key pair .
if [[ $(_are_we_have_to_do 'ssh-pubkey') ]]; then
  [[ -d /root/.ssh ]] || mkdir -p /root/.ssh
  if [[ ! "${ssh_passphrase}" = "" ]] && \
    [[ ! -e /root/.ssh/${HOSTNAME}.private.key ]]; then
    ssh-keygen -t rsa -b 4096 -N ${ssh_passphrase} -C "${HOSTNAME}.ssh.key" -f /root/.ssh/${HOSTNAME}.ssh.key && \
      cat /root/.ssh/${HOSTNAME}.ssh.key.pub >> /root/.ssh/authorized_keys && \
      mv /root/.ssh/${HOSTNAME}.ssh.key /root/.ssh/${HOSTNAME}.private.key && \
      mv /root/.ssh/${HOSTNAME}.ssh.key.pub /root/.ssh/${HOSTNAME}.public.key && \
      chmod -R 600 /root/.ssh

    echo " SSH Key : /root/.ssh/${HOSTNAME}.private.key ." && \
    echo " SSH Key Passphrase : [${ssh_passphrase}] ." && \
    cat /root/.ssh/${HOSTNAME}.private.key && \

    _init_config_complete 'ssh-pubkey'
  else
    echo -e " there is no passphrase, so could not create key pair ."
  fi
else echo -e " SSH key already generated, check out directory \"/root/.ssh\" ."
fi

# set completed stamp to Environment .
[[ "${#init_config_initialized[@]}" -gt 0 ]] && \
  sed -i -e '/^export INIT_CONFIG_INITIALIZED=.*$/d' -e '/^$/d' /etc/profile.d/init.config.initialized.sh && \
  cat <<_EOT_>> /etc/profile.d/init.config.initialized.sh
export INIT_CONFIG_INITIALIZED=$(echo "${init_config_initialized[@]}" | sed -e 's/ /,/g')
_EOT_
