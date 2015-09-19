#!/bin/bash -x

set -e

VER=14.07
NAME=barrier_breaker
PROFILE=TLWR1043

# Extra packages
PACKAGES="ddns-scripts iperf kmod-ledtrig-heartbeat kmod-ledtrig-usbdev ppp-mod-pppoe luci luci-app-ddns luci-app-firewall luci-app-qos netstat-nat qos-scripts slurm tcpdump-mini mwan3 luci-app-mwan3"

# Include VDSL firmware and SSH keys, etc
FILES=files

# Fetch imagebuilder tarball if doesn't exist
if [ ! -f OpenWrt-ImageBuilder-ar71xx_generic-for-linux-x86_64.tar.bz2 ]; then
    URL=https://downloads.openwrt.org/${NAME}/${VER}/ar71xx/generic/OpenWrt-ImageBuilder-ar71xx_generic-for-linux-x86_64.tar.bz2
    if hash axel 2>/dev/null; then
        axel -a $URL -o OpenWrt-ImageBuilder-ar71xx_generic-for-linux-x86_64.tar.bz2
    else
        wget $URL -o OpenWrt-ImageBuilder-ar71xx_generic-for-linux-x86_64.tar.bz2
    fi
fi

if [ ! -d OpenWrt-ImageBuilder-ar71xx_generic-for-linux-x86_64 ]; then
    rm -fr OpenWrt-ImageBuilder-ar71xx_generic-for-linux-x86_64
fi

tar xf OpenWrt-ImageBuilder-ar71xx_generic-for-linux-x86_64.tar.bz2
cd OpenWrt-ImageBuilder-ar71xx_generic-for-linux-x86_64

# Copy custom files
[ -e files ] && rm -fr files
mkdir files
[ -d ../../files ] && cp -r ../../files/* files/
[ -d ../files ] && cp -r ../files/* files/

# Enable online repos for fetching extra packages
> repositories.conf
for REPO in packages oldpackages luci; do
  echo "src/gz ${NAME}_${REPO} http://downloads.openwrt.org/${NAME}/${VER}/ar71xx/generic/packages/${REPO}" >> repositories.conf
done
echo "src imagebuilder file:packages" >> repositories.conf

# Build image
make image PROFILE=$PROFILE PACKAGES="$PACKAGES" FILES=$FILES

[ -d ../builds ] || mkdir ../builds
mv -v bin/ar71xx/openwrt-ar71xx-generic-tl-wr1043nd-v1-squashfs-sysupgrade.bin ../builds/openwrt-${PROFILE}-${NAME}_${VER}-$(date --iso)-squashfs-sysupgrade-imagebuilder.image
echo "New image at ../builds/openwrt-${PROFILE}-${NAME}_${VER}-$(date --iso)-squashfs-imagebuilder.image"

# Clean up
cd ..
rm -fr OpenWrt-ImageBuilder-ar71xx_generic-for-linux-x86_64
