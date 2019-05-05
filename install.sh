#!/bin/bash

set -e

INSTALL_HOSTNAME="archlinux"
INSTALL_USER_GROUPS="wheel,storage,power,docker,autologin,audio"
INSTALL_USER=""
INSTALL_LANG="en_US uk_UA"
INSTALL_REGION="Europe"
INSTALL_CITY="Kiev"
INSTALL_DIR="${1}"

help() {
    cat <<_EOF_
install.sh: Installs archlinux system

Usage: install.sh DIR
_EOF_
}

if [ $# < 1 ]; then
    help
    exit 1
fi

timedatectl set-ntp true

pacstrap ${INSTALL_DIR} base base-devel git

genfstab -U ${INSTALL_DIR} >> ${INSTALL_DIR}/etc/fstab

arch-chroot ${INSTALL_DIR}

ln -sf /usr/share/zoneinfo/${INSTALL_REGION}/${INSTALL_CITY} /etc/localtime
hwclock --systohc

for l in ${INSTALL_LANG}
do
    sed -i /etc/locale.gen -e "s/#${l}/${l}/"
done

echo "LANG=en_US.UTF-8" > /etc/locale.conf
locale-gen

echo ${INSTALL_HOSTNAME} > /etc/hostname

cat > /etc/hosts <<_EOF_
127.0.0.1 localhost
::1 localhost
127.0.1.1 ${INSTALL_HOSTNAME}.localdomain ${INSTALL_HOSTNAME}
_EOF_

systemctl enable dhcpcd

useradd -m -g users -G ${INSTALL_USER_GROUPS} -s /bin/bash ${INSTALL_USER}

echo "Enter password for root"
passwd

echo "Enter password for ${INSTALL_USER}"
passwd

pacman -S grub
grub-install --target=i386-pc ${INSTALL_DRIVE}
grub-mkconfig > /boot/grub/grub.cfg

# Install packages
pacman -Syyuu
git clone https://aur.archlinux.yaourt.git /tmp
(cd /tmp/yaourt; makepkg -si)

pacman -S ${PACKAGES} --noconfirm --needed
yaourt -S ${PACKAGES_AUR} --noconfirm
