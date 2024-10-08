#!/bin/sh

patch -p3 < fairylinux.patch
SHASUM=`sha512sum lts.x86_64.config`
sed -r "s/^[[:xdigit:]]+[[:blank:]]+lts.x86_64.config/$SHASUM/g" APKBUILD > APKBUILD.tmp && mv -f APKBUILD.tmp APKBUILD
