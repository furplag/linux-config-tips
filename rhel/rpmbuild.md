# Virtual machine for building RPM

## TL;DR
1. [install packages](#install-packages).
2. create "mock" user.
3. [build RPM](build-rpm).

### Install Packages
```bash
# yum install -y mock rpmdevtools rpm-build yum-utils
```

### Create "mock" user.
```bash
# useradd mockbuild -U -r -s /sbin/nologin
```

### Build RPM
###### Note: Building RPMs should NEVER be done with the root user.

```bash
### create directory
$ rpmdev-setuptree

### modify macros to ignore debugging resources.
$ echo -e "\n%debug_package %{nil}\n" >> $HOME/.rpmmacros

### extract source-package.
$ rpm -ivh [path-to-source-rpm.src.rpm]

### building Package.
$ rpmbuild -bs ~/rpmbuild/SPECS/[spec-file-of-rpm.spec]

### retrieve dependencies.
$ sudo yum-builddep -y ~/rpmbuild/SRPMS/[errord-rpm].src.rpm

### then re-build
$ rpmbuild --rebuild ~/rpmbuild/SRPMS/[errord-rpm].src.rpm

### build out RPMs in rpmbuild/RPMS/[arch] directory.
```
