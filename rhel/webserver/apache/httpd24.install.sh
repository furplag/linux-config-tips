#!/bin/bash
releasever=$(cat /etc/redhat-release | sed -n -e 1p | sed -e 's/^.*release *//' | cut -d '.' -f 1)

yum install -y -q epel-release \
"http://www.city-fan.org/ftp/contrib/yum-repo/city-fan.org-release-1-13.rhel${releasever}.noarch.rpm" \
"https://dl.iuscommunity.org/pub/ius/stable/Redhat/${releasever}/x86_64/ius-release-1.0-14.ius.el${releasever}.noarch.rpm" \
>/dev/null

sed -i -e 's/enabled=1/enabled=0/' /etc/yum.repos.d/{city-fan.org,epel,ius}*.repo

curl -fjkL https://raw.githubusercontent.com/furplag/linux-config-tips/yum-repo/RPM-GPG-KEY-furplag.github.io \
-o /etc/pki/rpm-gpg/RPM-GPG-KEY-furplag.github.io

cat <<_EOT_> /etc/yum.repos.d/furplag.github.io.repo
[furplag.github.io]
name=Packages only for me own.
baseurl=https://raw.githubusercontent.com/furplag/linux-config-tips/yum-repo/rhel/\$releasever/x86_64
priority=10
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-furplag.github.io

[furplag.github.io-source]
name=Packages only for me own.
baseurl=https://raw.githubusercontent.com/furplag/linux-config-tips/yum-repo/rhel/\$releasever/source
priority=10
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-furplag.github.io

_EOT_

yum install -y -q openssl --enablerepo=furplag.github.io >/dev/null
yum install -y -q nghttp2 libnghttp2 --enablerepo=epel >/dev/null
if [ "$releasever" -gt 6 ]; then
  yum install -y -q libmetalink libpsl libssh2 --enablerepo=city-fan.org >/dev/null
else
  yum install -y -q libmetalink libssh2 --enablerepo=city-fan.org >/dev/null
fi
yum install -y -q curl libcurl --enablerepo=furplag.github.io >/dev/null
yum install -y -q apr15u apr15u-util --enablerepo=ius >/dev/null
yum install -y -q httpd24u mod24u_ssl --enablerepo=furplag.github.io >/dev/null

echo "Done."

exit 0
