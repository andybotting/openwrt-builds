#!/bin/bash -x

set -e

VER=15.05
NAME=chaos_calmer
TARGET=ar71xx
ARCH=generic
PROFILE=TLWR1043
OUTPUT_NAME=tl-wr1043nd-v1

# Extra packages
PACKAGES="ddns-scripts ddns-scripts_no-ip_com igmpproxy iperf kmod-ledtrig-heartbeat kmod-ledtrig-usbdev ppp-mod-pppoe luci luci-app-ddns luci-app-firewall luci-app-qos qos-scripts tcpdump-mini mwan3 luci-app-mwan3"

# Include VDSL firmware and SSH keys, etc
FILES=files

# Fetch imagebuilder tarball if doesn't exist
IB_NAME=OpenWrt-ImageBuilder-${VER}-${TARGET}-${ARCH}.Linux-x86_64
if [ ! -f ${IB_NAME}.tar.bz2 ]; then
    URL=https://downloads.openwrt.org/${NAME}/${VER}/${TARGET}/${ARCH}/${IB_NAME}.tar.bz2
    if hash axel 2>/dev/null; then
        axel -a $URL -o ${IB_NAME}.tar.bz2
    else
        wget $URL -o ${IB_NAME}.tar.bz2
    fi
fi

[ -d $IB_NAME ] && rm -fr $IB_NAME
tar xf ${IB_NAME}.tar.bz2
cd $IB_NAME

# Copy custom files
[ -e files ] && rm -fr files
mkdir files
[ -d ../../files ] && cp -r ../../files/* files/
[ -d ../files ] && cp -r ../files/* files/

# Build image
make image PROFILE=$PROFILE PACKAGES="$PACKAGES" FILES=$FILES

[ -d ../builds ] || mkdir ../builds
cp -r bin/${TARGET}/openwrt-${VER}-${TARGET}-${ARCH}-${OUTPUT_NAME}-squashfs-sysupgrade.bin ../builds/openwrt-${PROFILE}-${NAME}_${VER}-$(date --iso)-squashfs-sysupgrade-imagebuilder.bin
cp -r bin/${TARGET}/openwrt-${VER}-${TARGET}-${ARCH}-${OUTPUT_NAME}-squashfs-factory.bin ../builds/openwrt-${PROFILE}-${NAME}_${VER}-$(date --iso)-squashfs-factory-imagebuilder.bin

# Clean up
cd ..
rm -fr $IB_NAME
