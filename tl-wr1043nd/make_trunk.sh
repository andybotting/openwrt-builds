#!/bin/bash -x

set -e

MODEL=tl-wr1043nd-v1
TAG=trunk

if [ -d trunk ]; then
    cd trunk
    svn update
    make clean
    rm -fr trunk/build_dir trunk/staging_dir trunk/tmp trunk/.config
else
    svn checkout svn://svn.openwrt.org/openwrt/trunk
    cd trunk
fi

# Edit feeds to remove xwrt and telephony
cp feeds.conf.default feeds.conf
sed -i '/^src-svn xwrt.*/ s/^/#/' feeds.conf
sed -i '/^src-git telephony.*/ s/^/#/' feeds.conf

# Symlink dl directory
if [ ! -L dl ]; then
    rm -fr dl
    ln -s ../../dl .
fi

# Copy custom files
[ -e files ] && rm -fr files
mkdir files
[ -d ../../files ] && cp -r ../../files/* files/
[ -d ../files ] && cp -r ../files/* files/

make defconfig
./scripts/feeds update
./scripts/feeds install -a
make package/symlinks
make prereq

cat  > .config <<EOF
CONFIG_TARGET_ar71xx=y
CONFIG_TARGET_ar71xx_generic=y
CONFIG_TARGET_ar71xx_generic_TLWR1043ND=y

CONFIG_ATH_USER_REGD=y
CONFIG_PACKAGE_kmod-ledtrig-heartbeat=y
CONFIG_PACKAGE_kmod-usb-core
CONFIG_PACKAGE_kmod-usb-ohci

CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-app-ddns=y
CONFIG_PACKAGE_luci-app-firewall=y
CONFIG_PACKAGE_luci-app-qos=y
CONFIG_PACKAGE_luci-proto-core=y
CONFIG_PACKAGE_luci-proto-ipv6=y
CONFIG_PACKAGE_luci-proto-ppp=y

CONFIG_PACKAGE_ddns-scripts=y
CONFIG_PACKAGE_ddns-scripts_no-ip_com=y
CONFIG_PACKAGE_iperf=y
CONFIG_PACKAGE_qos-scripts=y
CONFIG_PACKAGE_tcpdump-mini=y
EOF

make defconfig

echo "Fetching packages..."
make V=s download

echo "Building..."
make -j$(nproc)

NAME="openwrt-${MODEL}-${TAG}-r$(svnversion)-$(date --iso)"
[ -d ../builds ] || mkdir ../builds
cp bin/ar71xx/openwrt-ar71xx-generic-${MODEL}-squashfs-sysupgrade.bin ../builds/${NAME}-sysupgrade.image
cp .config ../builds/${NAME}.config
