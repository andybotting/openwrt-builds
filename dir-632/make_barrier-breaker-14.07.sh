#!/bin/bash -x

set -e

MODEL=DIR632A1
BRANCH=14.07
DIR=openwrt

if [ -d $DIR ]; then
	cd $DIR
	make clean
	rm -fr $DIR/build_dir $DIR/staging_dir $DIR/tmp $DIR/.config
else
    git clone git://git.openwrt.org/${BRANCH}/openwrt.git $DIR
	cd $DIR
	patch -p1 < ../patches/add-dlink-dir632-support-${BRANCH}.patch
fi

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

cat > .config <<EOF
CONFIG_TARGET_ar71xx=y
CONFIG_TARGET_ar71xx_generic=y
CONFIG_TARGET_ar71xx_generic_DIR632A1=y

CONFIG_PACKAGE_kmod-ledtrig-heartbeat=y
CONFIG_PACKAGE_kmod-usb-serial=y
CONFIG_PACKAGE_kmod-usb-serial-option=y
CONFIG_PACKAGE_kmod-usb-serial-wwan=y

CONFIG_ATH_USER_REGD=y
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-app-ddns=y
CONFIG_PACKAGE_luci-app-firewall=y
CONFIG_PACKAGE_luci-app-qos=y
CONFIG_PACKAGE_luci-proto-core=y
CONFIG_PACKAGE_luci-proto-ppp=y
CONFIG_PACKAGE_luci-proto-3g=y

CONFIG_PACKAGE_qos-scripts=y

CONFIG_PACKAGE_kmod-usb-net-cdc-ether=y
CONFIG_PACKAGE_kmod-usb-net-rndis=y
CONFIG_PACKAGE_kmod-usb-net-sierrawireless=y
CONFIG_PACKAGE_kmod-usb-serial-sierrawireless=y

CONFIG_PACKAGE_chat=y
CONFIG_PACKAGE_usb-modeswitch=y
CONFIG_PACKAGE_comgt=y
CONFIG_PACKAGE_microcom=y
CONFIG_PACKAGE_usbutils=y
EOF

make defconfig

echo "Fetching packages..."
make V=s download

echo "Building..."
make V=s -j$(nproc)

NAME="openwrt-ar71xx-generic-dir-632-a1-squashfs-${BRANCH}-$(date --iso)"
[ -d ../builds ] || mkdir ../builds
cp bin/ar71xx/openwrt-ar71xx-generic-dir-632-a1-squashfs-sysupgrade.bin ../builds/${NAME}-sysupgrade.bin
cp .config ../builds/${NAME}.config
