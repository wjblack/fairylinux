# FairyLinux build system
# (C) 2023 FairyLinux.org and BJ Black <bj@fairylinux.org>

# This file is licensed under the GNU General Public License, Version 2.

# Build the userland that's eventually jammed into the kernel initramfs.
FROM alpine:latest AS user

RUN apk update && apk add cpio
ADD inittab /etc/inittab
RUN ln -s /sbin/init /init
RUN mkdir -p /boot && find / -xdev | egrep -v ^/boot | cpio -H newc -o > /boot/fairylinux.cpio


# Download and build the current-version Linux kernel
FROM alpine:latest AS build

ARG variant=default

RUN apk update && apk add alpine-sdk
RUN adduser -D bj && git config --global user.name "FairyLinux Build System" && git config --global user.email "bj@fairylinux.org"
RUN su bj -c 'cd /home/bj && git clone https://gitlab.alpinelinux.org/alpine/aports'
ADD abuild.rsa* /home/bj/.abuild/
RUN echo 'PACKAGER_PRIVKEY=/home/bj/.abuild/abuild.rsa' > /home/bj/.abuild/abuild.conf
RUN chown -R bj /home/bj/.abuild && chmod 0700 /home/bj/.abuild && chmod 0600 /home/bj/.abuild/*
RUN adduser bj abuild
RUN su bj -c 'cd /home/bj/aports/main/linux-lts && git checkout 3.18-stable'
ADD fairylinux.patch patch-abuild.sh /home/bj/aports/main/linux-lts/
COPY --from=user /boot/fairylinux.cpio /home/bj/aports/main/linux-lts/fairylinux.cpio
RUN chown bj /home/bj/aports/main/linux-lts/* && chmod 0755 /home/bj/aports/main/linux-lts/patch-abuild.sh
RUN su bj -c 'cd /home/bj/aports/main/linux-lts && ./patch-abuild.sh'
RUN su bj -c 'cd /home/bj/aports/main/linux-lts && abuild -rK'
