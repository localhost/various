#!/usr/bin/env sh
#
# installs Alpine Linux in a chroot
#   -> expects formatted partitions
#   -> needs blkid, curl, and egrep
#
# last change: 2020-10-20

# TODO: figure out why XFS on root won't boot

hostname=cms
mbr=/dev/sda
partitions="/dev/sda3=/;/dev/sda1=/boot;/dev/sda4=/var;/dev/sda2=swap" # root must be first!
chroot_dir=/mnt

version=3.12
arch=x86_64
mirror="http://uk.alpinelinux.org/alpine"
apk_version=

add_dropbear=y

curl_opts="-g -m10 -L"

mkdir -p ${chroot_dir} && cd ${chroot_dir}

i=0
echo -n > /tmp/fstab
while [ "${partitions}" ]; do
  d=${partitions%%;*}
  drive=${d%=*}
  part=${d#*=}

  uuid=$(blkid -s UUID -o value ${drive})
  type=$(blkid -s TYPE -o value ${drive})
  if [ "${type}" = "xfs" ]; then use_xfs=y; fi

  if [ ! "${part}" = "swap" ]; then
    echo "UUID=${uuid} ${part} ${type} defaults,relatime 0 0" >> /tmp/fstab
    mkdir -p "${chroot_dir}${part}"
    mount -t ${type} "${drive}" "${chroot_dir}${part}"
  else
    echo "UUID=${uuid} swap swap defaults 0 0" >> /tmp/fstab
  fi

  [ "${partitions}" = "${d}" ] && partitions='' || partitions="${partitions#*;}"
done

if [ -z "${apk_version}" ]; then
  apk_tools=$(curl ${curl_opts} -s "${mirror}/v${version}/main/${arch}/" | grep -Eio 'apk-tools-static-.*\.apk"' | cut -d'"' -f1)
else
  apk_tools="apk-tools-static-${apk_version}.apk"
fi

rm -f "${apk_tools}"
curl ${curl_opts} -O "${mirror}/v${version}/main/${arch}/${apk_tools}"
tar xzf ${apk_tools} && rm "${apk_tools}"

./sbin/apk.static -X "${mirror}/v${version}/main" -U --allow-untrusted --root "${chroot_dir}" --initdb add alpine-base

mv /tmp/fstab ${chroot_dir}/etc/fstab

echo ${hostname} > ${chroot_dir}/etc/hostname
cp /etc/resolv.conf ${chroot_dir}/etc/resolv.conf

mkdir -p ${chroot_dir}/etc/apk
echo "${mirror}/v${version}/main" > ${chroot_dir}/etc/apk/repositories

mkdir -p ${chroot_dir}/boot
chroot-prepare ${chroot_dir}

chroot ${chroot_dir} /bin/mount -a

chroot ${chroot_dir} /sbin/apk update
chroot ${chroot_dir} /sbin/apk add attr binutils coreutils curl dialog findutils git git-perl grep less lsof pciutils readline rsync sed util-linux

if [ ! -z "${use_xfs}" ]; then
  chroot ${chroot_dir} /sbin/apk add xfsprogs xfsprogs-extra
fi

chroot ${chroot_dir} /sbin/rc-update add devfs sysinit
chroot ${chroot_dir} /sbin/rc-update add dmesg sysinit
chroot ${chroot_dir} /sbin/rc-update add mdev sysinit

chroot ${chroot_dir} /sbin/rc-update add hwclock boot
chroot ${chroot_dir} /sbin/rc-update add modules boot
chroot ${chroot_dir} /sbin/rc-update add sysctl boot
chroot ${chroot_dir} /sbin/rc-update add hostname boot
chroot ${chroot_dir} /sbin/rc-update add bootmisc boot
chroot ${chroot_dir} /sbin/rc-update add syslog boot

chroot ${chroot_dir} /sbin/rc-update add mount-ro shutdown
chroot ${chroot_dir} /sbin/rc-update add killprocs shutdown
chroot ${chroot_dir} /sbin/rc-update add savecache shutdown

chroot ${chroot_dir} /sbin/apk add linux-lts syslinux
chroot ${chroot_dir} /bin/dd if=/usr/share/syslinux/mbr.bin of=${mbr}
chroot ${chroot_dir} /sbin/extlinux -i /boot

cat > ${chroot_dir}/etc/network/interfaces <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
  hostname haiwo
EOF
chroot ${chroot_dir} /sbin/rc-update add networking

if [ "${add_dropbear}" = "y" ]; then
  chroot ${chroot_dir} /sbin/apk add dropbear
  chroot ${chroot_dir} /sbin/rc-update add dropbear
fi

echo -n "Set root password (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
  chroot ${chroot_dir} passwd root
fi

echo -n "Unmount all (y/n)? "
read answer
if [ "$answer" != "${answer#[Yy]}" ]; then
  cd ~
  umount ${chroot_dir}/* ${chroot_dir}
fi
