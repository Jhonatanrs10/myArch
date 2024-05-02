#!/usr/bin/env bash
myBase="pulseaudio pulseaudio-bluetooth samba xarchiver papirus-icon-theme breeze-gtk xcursor-comix ntfs-3g dosfstools os-prober nano vim git neofetch gufw gst-plugins-ugly gst-plugins-good gst-plugins-base gst-plugins-bad gst-libav gstreamer ffmpeg fwupd samba gvfs-smb flatpak gvfs gvfs-mtp gvfs-smb udisks2 polkit polkit-gnome net-tools bluez bluez-tools bluez-utils joyutils man-db gnu-free-fonts noto-fonts noto-fonts-cjk noto-fonts-emoji cmatrix htop"
myI3wm="i3 picom lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings font-manager dmenu rofi i3lock i3status feh imagemagick nitrogen acpilight volumeicon pcmanfm scrot xsel terminology lxrandr lxappearance xfce4-taskmanager xfce4-power-manager xfce4-appfinder galculator system-config-printer blueman pavucontrol network-manager-applet wireless_tools xreader mpv gparted chromium code qbittorrent"
myXfce="xfce4 lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings font-manager xfce4-screenshooter xfce4-pulseaudio-plugin blueman pavucontrol thunar thunar-archive-plugin thunar-media-tags-plugin thunar-volman network-manager-applet xreader mpv galculator system-config-printer"
myGnome="gnome gdm"

loadkeys br-abnt
while [ "$EXITWHILE" != "yes" ];
do
    lsblk
    echo "Digite o caminho da particao/disco: (exemplo /dev/sda1)"
    read BARRADEV
    cfdisk $BARRADEV
    echo "Digite yes para sair do CFDISK"
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

echo "Digite (yes) para criar uma particao Home separada"
read HOME 

# Configurando Particoes
echo "Digite (yes) para formatar a particao EFI (em caso de dualboot digite nao)"
read NEWEFI

if [[ $NEWEFI == 'yes' ]]
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
if [[ $HOME == 'yes' ]]
then
    lsblk
    echo "Digite o caminho da particao Home(/home): (exemplo /dev/sda4)"
    read HOME
    mkfs.ext4 "${HOME}"
    mount "${HOME}" /mnt/home
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
echo "arch" > /etc/hostname
echo "arch" > /etc/hostname
cat <<EOF > /etc/hosts
127.0.0.1	localhost
::1			localhost
127.0.1.1	arch.localdomain	arch
EOF
pacman -S $myBase
systemctl enable NetworkManager bluetooth
if [[ $DESKTOP == '1' ]]
then 
    pacman -S $myI3wm --noconfirm --needed
    systemctl enable lightdm
elif [[ $DESKTOP == '2' ]]
then
    pacman -S $myGnome --noconfirm --needed
    systemctl enable gdm
else
    echo "Sem interface"
fi
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
exit
REALEND

arch-chroot /mnt sh next.sh

echo "Final Manual Commands
umount -a
reboot
"

