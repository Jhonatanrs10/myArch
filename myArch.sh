#!/usr/bin/env bash

loadkeys br-abnt
cfdisk
lsblk

echo "Please enter EFI paritition: (example /dev/sda1 or /dev/nvme0n1p1)"
read EFI

echo "Please enter SWAP paritition: (example /dev/sda2)"
read SWAP

echo "Please enter Root(/) paritition: (example /dev/sda3)"
read ROOT 

echo "Please enter your username"
read USER 

echo "Please enter your password"
read PASSWORD 

# make filesystems
echo -e "\nCreating Filesystems...\n"

mkfs.vfat -F32 -n "EFISYSTEM" "${EFI}"
mkswap "${SWAP}"
swapon "${SWAP}"
mkfs.ext4 -L "ROOT" "${ROOT}"

# mount target
mount -t ext4 "${ROOT}" /mnt
mkdir -p /mnt/boot/efi
mount -t vfat "${EFI}" /mnt/boot/efi

echo "--------------------------------------"
echo "INSTALLING Arch Linux BASE on Main Drive"
echo "--------------------------------------"

pacstrap /mnt base base-devel linux linux-firmware --noconfirm --needed

echo "--------------------------------------"
echo "Setup Dependencies"
echo "--------------------------------------"

pacstrap /mnt networkmanager network-manager-applet wireless_tools nano intel-ucode git sof-firmware grub efibootmgr terminology ntfs-3g dosfstools os-prober --noconfirm --needed

# fstab
genfstab -U /mnt >> /mnt/etc/fstab

# next
cat <<REALEND > /mnt/next.sh

useradd -m $USER
usermod -aG wheel,storage,power,audio $USER
echo $USER:$PASSWORD | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

echo "-------------------------------------------------"
echo "Setup Language to US and set locale"
echo "-------------------------------------------------"
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

ln -sf /user/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc

echo "arch" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.1.1	arch.localdomain	arch
EOF

i3wmSetup
i3wmConfig
i3wmTouchpad

grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg

exit

REALEND

arch-chroot /mnt sh next.sh
umount -a

