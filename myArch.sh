#!/usr/bin/env bash

loadkeys br-abnt
cfdisk
clear
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

#executing
mkfs.ext4 "${ROOT}"
mkfs.fat -F 32 "${EFI}"
mkswap "${SWAP}"
swapon "${SWAP}"

# mount target
mount "${ROOT}" /mnt
mkdir -p /mnt/boot/efi
mount "${EFI}" /mnt/boot/efi

lsblk
sleep 5

echo "--------------------------------------"
echo "INSTALLING myArch Linux BASE on Main Drive"
echo "--------------------------------------"

pacstrap /mnt base base-devel linux linux-firmware networkmanager network-manager-applet wireless_tools nano intel-ucode git sof-firmware grub efibootmgr terminology ntfs-3g dosfstools os-prober --noconfirm --needed

# fstab
genfstab /mnt
sleep 5
genfstab -U /mnt >> /mnt/etc/fstab

# next
cat <<REALEND > /mnt/next.sh
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
useradd -m $USER
usermod -aG wheel,storage,power,audio $USER
echo $USER:$PASSWORD | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=br-abnt2" >> /etc/vconsole.conf
echo "arch" > /etc/hostname
systemctl enable NetworkManager
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
exit
REALEND

arch-chroot /mnt sh next.sh
umount -a

