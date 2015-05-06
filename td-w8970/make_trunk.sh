#!/bin/bash -x

set -e

MODEL=TDW8970
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
CONFIG_TARGET_lantiq=y
CONFIG_TARGET_lantiq_xrx200=y
CONFIG_TARGET_lantiq_xrx200_TDW8970=y

CONFIG_ATH_USER_REGD=y
CONFIG_PACKAGE_kmod-ledtrig-heartbeat=y
CONFIG_PACKAGE_kmod-usb-core
CONFIG_PACKAGE_kmod-usb-ohci

CONFIG_PACKAGE_kmod-libphy=y
CONFIG_PACKAGE_kmod-mii=y
CONFIG_PACKAGE_kmod-usb-dwc2=y
CONFIG_PACKAGE_kmod-usb-net=y
CONFIG_PACKAGE_kmod-usb-net-asix=y

CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-app-ddns=y
CONFIG_PACKAGE_luci-app-firewall=y
CONFIG_PACKAGE_luci-app-qos=y
CONFIG_PACKAGE_luci-proto-core=y
CONFIG_PACKAGE_luci-proto-ipv6=y
CONFIG_PACKAGE_luci-proto-ppp=y

CONFIG_PACKAGE_ddns-scripts=y
CONFIG_PACKAGE_iperf=y
CONFIG_PACKAGE_qos-scripts=y
CONFIG_PACKAGE_tcpdump-mini=y
CONFIG_PACKAGE_igmpproxy=y
EOF

make defconfig

echo "Fetching packages..."
make V=s download

echo "Building..."
make -j$(nproc)

NAME="openwrt-${MODEL}-${TAG}-r$(svnversion)-$(date --iso)"
[ -d ../builds ] || mkdir ../builds
cp bin/lantiq/openwrt-lantiq-xrx200-TDW8970-sysupgrade.image ../builds/${NAME}-sysupgrade.image
cp .config ../builds/${NAME}.config
