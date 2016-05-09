# Install Oracle JDK with "alternatives"

## TL;DR
1. Install Oracle JDK.
2. Does not remove previous version of JDK, if "yum update jdk" runs.
3. Set "alternatives" for JDK.
4. Set $JAVA_HOME (relate to alternatives config).

## Getting start
+ [Install Oracle JDK 6 with "alternatives"](jdk.6.md)
+ [Install Oracle JDK 7 with "alternatives"](jdk.7.md)
+ [Install Oracle JDK 8 with "alternatives"](jdk.8.md)

## Quickstart
see [this](jdk.install.sh).
```bash
curl https://raw.githubusercontent.com/furplag/linux-config-tips/master/rhel/java/jdk.install.sh -O && \
 chmod +x jdk.install.sh && \
 ./jdk.install.sh -h
```
