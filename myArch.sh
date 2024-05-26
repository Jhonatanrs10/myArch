#!/usr/bin/env bash

loadkeys br-abnt
while [[ $EXITWHILE != 1 ]];
do
    lsblk
    echo "[CFDISK] Digite o caminho da particao/disco: (exemplo /dev/sda)"
    read BARRADEV
    cfdisk $BARRADEV
    echo "Digite (1) para sair do CFDISK"
    read EXITWHILE
done

clear
lsblk
sleep 2
echo "Digite o caminho da particao EFI: (exemplo /dev/sda1)"
read EFI

echo "Digite o caminho da particao SWAP: (exemplo /dev/sda2)"
read SWAP

echo "Digite o caminho da particao Root(/): (exemplo /dev/sda3)"
read ROOT

echo "Digite (1) para criar uma particao Home separada"
read HOME 

# Configurando Particoes
echo "Digite (1) para (NAO) formatar a particao EFI ($EFI):"
read NEWEFI

if [[ $NEWEFI != 1 ]]
then
    mkfs.fat -F 32 "${EFI}"
fi

mkfs.ext4 "${ROOT}"
mkswap "${SWAP}"
swapon "${SWAP}"

# Montando Particoes
mount "${ROOT}" /mnt
mkdir -p /mnt/boot
mkdir -p /mnt/home
mount "${EFI}" /mnt/boot
if [[ $HOME == 1 ]]
then
    lsblk
    echo "Digite o caminho da particao Home(/home): (exemplo /dev/sda4)"
    read HOME
    echo "Digite (1) para formatar a Home ($HOME):"
    read NEWHOME
    if [[ $NEWHOME == 1 ]]
    then
        mkfs.ext4 "${HOME}"
    fi
    mount "${HOME}" /mnt/home
fi

clear
lsblk

echo "Digite seu nome de usuario:"
read USER 

echo "Digite sua senha de usuario"
read PASSWORD 

echo "Digite a senha do ROOT"
read ROOTPASSWORD

# Linux Base
pacstrap /mnt base linux linux-firmware --noconfirm --needed

# Fstab
genfstab /mnt >> /mnt/etc/fstab

# Next
cat <<REALEND > /mnt/next.sh
pacman -S base-devel networkmanager nano intel-ucode git sof-firmware grub efibootmgr ntfs-3g dosfstools os-prober --noconfirm --needed
systemctl enable NetworkManager --now
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
setxkbmap -model abnt2 -layout br
tee /etc/X11/xorg.conf.d/10-evdev.conf <<< 'Section "InputClass"
Identifier "evdev keyboard catchall"
MatchIsKeyboard "on"
MatchDevicePath "/dev/input/event*"
Driver "evdev"
Option "XkbLayout" "br"
Option "XkbVariant" "abnt2"
EndSection'
echo "root:$ROOTPASSWORD" | chpasswd
useradd -m $USER
usermod -aG wheel,storage,power,audio $USER
echo $USER:$PASSWORD | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=br-abnt2" >> /etc/vconsole.conf
echo "arch" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1		localhost
127.0.1.1	arch.localdomain	arch
EOF
cp /etc/pacman.conf /etc/pacman.conf.bkp
cp /etc/default/grub /etc/default/grub.bkp
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 10\nILoveCandy\nColor/g' /etc/pacman.conf
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
sed -i "/GRUB_DISABLE_OS_PROBER=false/"'s/^#//' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
pacman -Syyu
echo "
Now [exit] and [umount -a] and then [reboot]"
REALEND

arch-chroot /mnt sh next.sh


