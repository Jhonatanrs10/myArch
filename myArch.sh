#!/usr/bin/env bash

myBase="xorg pulseaudio pulseaudio-bluetooth samba xarchiver papirus-icon-theme breeze-gtk xcursor-comix ntfs-3g dosfstools os-prober nano vimp git neofetch gufw gst-plugins-ugly gst-plugins-good gst-plugins-base gst-plugins-bad gst-libav gstreamer ffmpeg fwupd samba gvfs-smb flatpak gvfs gvfs-mtp gvfs-smb udisks2 polkit polkit-gnome net-tools bluez bluez-tools bluez-utils man-db gnu-free-fonts noto-fonts noto-fonts-cjk noto-fonts-emoji cmatrix htop"
myI3wm="i3 lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings font-manager dmenu rofi i3lock i3status feh imagemagick nitrogen acpilight volumeicon pcmanfm scrot xsel terminology lxrandr lxappearance xfce4-taskmanager xfce4-power-manager galculator system-config-printer blueman pavucontrol network-manager-applet wireless_tools"
myGnome="gnome gdm"
myApps="gparted chromium firefox code vlc mpv"

loadkeys br-abnt
cfdisk
clear
lsblk
sleep 5
clear
echo "Digite o caminho da particao EFI: (exemplo /dev/sda1)"
read EFI

echo "Digite o caminho da particao SWAP: (exemplo /dev/sda2)"
read SWAP

echo "Digite o caminho da particao Root(/): (exemplo /dev/sda3)"
read ROOT 

echo "Digite (yes) para criar uma particao Home separada"
read HOME 

# Configurando Particoes
mkfs.ext4 "${ROOT}"
mkfs.fat -F 32 "${EFI}"
mkswap "${SWAP}"
swapon "${SWAP}"

# Montando Particoes
mount "${ROOT}" /mnt
mkdir -p /mnt/boot/efi
mkdir -p /mnt/home
mount "${EFI}" /mnt/boot/efi
if [[ $HOME == 'yes' ]]
then
    lsblk
    echo "Digite o caminho da particao Home(/home): (exemplo /dev/sda4)"
    read HOME
    mkfs.ext4 "${HOME}"
    mount "${HOME}" /mnt/home
else
    echo "Home no /"
fi

clear
lsblk

echo "Digite seu nome de usuario:"
read USER 

echo "Digite sua senha de usuario"
read PASSWORD 

echo "Escolha qual interface usar:"
echo "1. I3WM"
echo "2. GNOME"
echo "3. NoDesktop"
read DESKTOP

# Linux Base
pacstrap /mnt base base-devel linux linux-firmware networkmanager nano intel-ucode git sof-firmware grub efibootmgr ntfs-3g dosfstools os-prober --noconfirm --needed

# Fstab
genfstab /mnt >> /mnt/etc/fstab

# Next
cat <<REALEND > /mnt/next.sh
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc
echo "Digite a senha do usuario Root"
passwd
useradd -m $USER
usermod -aG wheel,storage,power,audio $USER
echo $USER:$PASSWORD | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=br-abnt2" >> /etc/vconsole.conf
setxkbmap -model abnt2 -layout br
echo "setxkbmap -model abnt2 -layout br" >> ~/.profile
sudo tee /etc/X11/xorg.conf.d/10-evdev.conf <<< 'Section "InputClass"
Identifier "evdev keyboard catchall"
MatchIsKeyboard "on"
MatchDevicePath "/dev/input/event*"
Driver "evdev"
Option "XkbLayout" "br"
Option "XkbVariant" "abnt2"
EndSection'
echo "Arch" > /etc/hostname
pacman -S $myBase
systemctl enable NetworkManager bluetooth
if [[ $DESKTOP == '1' ]]
then 
    pacman -S $myI3wm $myApps --noconfirm --needed
    systemctl enable lightdm
elif [[ $DESKTOP == '2' ]]
then
    pacman -S $myGnome $myApps --noconfirm --needed
    systemctl enable gdm
else
    echo "Sem interface"
fi
grub-install /dev/sda
grub-mkconfig -o /boot/grub/grub.cfg
exit
REALEND

arch-chroot /mnt sh next.sh
umount -a

