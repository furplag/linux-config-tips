# Apache HTTP/2 on RHEL



## TL;DR
1. [Install OpenSSL 1.0.2](#1_install_openssl_102) (or later) .
2. Install nghttp2.
3. Install httpd24u, mod24u_ssl mod24u_session.

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
or [rpmbuild](../../rpmbuild.md).


## Quickstart
see [this](httpd24.install.sh).
```bash
curl https://raw.githubusercontent.com/furplag/linux-config-tips/master/rhel/java/jdk.install.sh -O && \
 chmod +x jdk.install.sh && \
 ./jdk.install.sh -h
```
