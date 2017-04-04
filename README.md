# AWS C++ SDK Debian packages

AWS C++ SDK packaged as .debs.

## Build

```sh
	make VERSION=<version>
```

## Install

Debs are published to http://dl.bintray.com/lucidsoftware/apt/

```
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 379CE192D401AB61
echo 'deb http://dl.bintray.com/lucidsoftware/apt/ main contrib' > /etc/apt/sources.list.d/lucidsoftware-contrib.list

apt-get update
apt-get install libaws-cpp-sdk-s3 # shared library
apt-get install libaws-cpp-sdk-s3-dev # headers
```
