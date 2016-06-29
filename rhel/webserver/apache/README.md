# Apache HTTP/2 on RHEL



## TL;DR
1. [Install OpenSSL 1.0.2](#1_install_openssl_102) (or later) .
2. [Install nghttp2](#2_install_nghttp2).
3. [Install Apache 2.4 over SSL](#3_install_apache_24_over_ssl).

## Getting start

### 1. Install OpenSSL 1.0.2
save as "/etc/yum.repos.d/furplag.github.io.repo".
```txt
[furplag.github.io]
name=Packages only for me own.
baseurl=https://raw.githubusercontent.com/furplag/linux-config-tips/yum-repo/rhel/$releasever/x86_64
priority=10
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-furplag.github.io

[furplag.github.io-source]
name=Packages only for me own.
baseurl=https://raw.githubusercontent.com/furplag/linux-config-tips/yum-repo/rhel/$releasever/source
priority=10
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-furplag.github.io
```
then
```bash
# curl -fjkL https://raw.githubusercontent.com/furplag/linux-config-tips/yum-repo/RPM-GPG-KEY-furplag.github.io \
  -o /etc/pki/rpm-gpg/RPM-GPG-KEY-furplag.github.io

# yum install -y openssl openssl-libs openssl-devel --enablerepo=furplag.github.io` .
```

or [rpmbuild](../../rpmbuild.md).
```bash
curl -LO https://dl.fedoraproject.org/pub/fedora/linux/updates/23/SRPMS/o/openssl-1.0.2h-1.fc23.src.rpm
curl -LO https://dl.fedoraproject.org/pub/fedora/linux/releases/23/Everything/source/SRPMS/c/crypto-policies-20150518-3.gitffe885e.fc23.src.rpm

$ rpmdev-setuptree
$ rpm -ivh openssl-1.0.2h-1.fc23.src.rpm
$ rpmbuild -ba ~/rpmbuild/SPECS/crypto-policies.spec
# yum install -y ~/rpmbuild/RPMS/noarch/crypto-policies-20150518-3.gitffe885e.el7.centos.noarch.rpm

$ rpm -ivh crypto-policies-20150518-3.gitffe885e.fc23.src.rpm
$ rpmbuild -ba ~/rpmbuild/SPECS/openssl.spec
# yum install -y ~/rpmbuild/RPMS/x86_64/openssl-1.0.2h-1.el7.centos.x86_64.rpm \
  ~/rpmbuild/RPMS/x86_64/openssl-libs-1.0.2h-1.el7.centos.x86_64.rpm \
  ~/rpmbuild/RPMS/x86_64/openssl-devel-1.0.2h-1.el7.centos.x86_64.rpm
```

### 2. Install nghttp2
That's it.
```bash
# yum install -y epel-release && sed -i -e 's/enabled=1/enabled=0/' /etc/yum.repos.d/epel*.repo
# yum install -y nghttp2 libnghttp2 --enablerepo=epel
```

### 3. Install Apache 2.4 over SSL

## Quickstart
see [this](httpd24.install.sh).
```bash
curl -LO https://raw.githubusercontent.com/furplag/linux-config-tips/master/rhel/java/httpd24.install.sh && \
 chmod +x httpd24.install.sh && \
 ./httpd24.install.sh
```
