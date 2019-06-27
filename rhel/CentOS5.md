# Necromancing - Building WordPress 3.x runnning under PHP 5.2 in 2019 via CentOS 5 .

## CentOS 5
Sadly, CentOS 5 end of life in 2017 already, so I tried out to finding resource can be usefull .

[CentOS 5 netinstall image](http://vault.centos.org/5.11/isos/x86_64/CentOS-5.11-x86_64-netinstall.iso)
  image url : http://vault.centos.org/5.11/os/x86_64/

### Step 1. enable to use YUM
No URLs, and mirrors alive any more,  
deactivate to mirrors, and replace `baseurl` to http://archive.kernel.org/centos-vault/ .
```bash
# disable to unusable repos .
sed -i -e 's/enabled=1/enabled=0/g' /etc/yum.repos.d/CentOS-Base.repo && \

# create repos from vault .
cat <<_EOT_>> /etc/yum.repos.d/CentOS-Vault.repo
  
[C5.11-base]
name=CentOS-5.11 - Base
baseurl=http://vault.centos.org/5.11/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5
enabled=0

[C5.11-updates]
name=CentOS-5.10 - Updates
baseurl=http://vault.centos.org/5.11/updates/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5
enabled=0

[C5.11-extras]
name=CentOS-5.11 - Extras
baseurl=http://vault.centos.org/5.11/extras/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5
enabled=0

[C5.11-centosplus]
name=CentOS-5.11 - Plus
baseurl=http://vault.centos.org/5.10/centosplus/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-5
enabled=0

_EOT_
### remember this option, --enablerepo=C5.11-base,C5.11-updates
```
### Step 2. Installing stale packages
```bash
# southbridge-stable
rpm --import http://rpms.southbridge.ru/RPM-GPG-KEY-southbridge && \
yum install -y http://rpms.southbridge.ru/southbridge-rhel5-stable.rpm

# southbridge-php52
yum --disablerepo=* --enablerepo=southbridge-stable install -y southbridge-php52-release && \
sed -i -e 's/enabled=1/enabled=0/g' /etc/yum.repos.d/southbridge*

# prerequirement
yum --disablerepo=* --enablerepo= C5.11-base,C5.11-updates install -y gmp libxslt openssl-devel

# PHP 5
yum --disablerepo=* --enablerepo=southbridge-stable,southbridge-php52 install php php-cli php-mysql php-mbstring php-xml
# ...setting up /etc/php.ini manually .

# MySQL 5.1
yum --disablerepo=* --enablerepo=southbridge-stable,southbridge-php52 install -y mysqlclient15 mysqlclient15-devel && \
yum  --disablerepo=* --enablerepo= C5.11-base,C5.11-updates install -y perl-DBD-MySQL && \
yum --disablerepo=* --enablerepo=southbridge-stable,southbridge-php52 install compat-mysql51 mysql-server
# ...setting up /etc/my.cnf manually .

# Apache 2.2
yum  --disablerepo=* --enablerepo= C5.11-base,C5.11-updates install -y httpd
# ...setting up /etc/httpd/httpd.conf manually .

# WordPress 3.6
wget https://ja.wordpress.org/wordpress-3.6.tar.gz && \
tar zxvf wordpress-3.6.tar.gz -C /var/www/.
chown -R apache:apache /var/www/wordpress
# ...setting up /var/www/wordpress/wp-config.php

```

Next Step, [Upgrade WordPress 3.6 on PHP5.2 to WordPress 5.x on PHP5.6](./CentOS5-PHP-5.2-to-5.6.md)


