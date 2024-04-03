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

echo "Please choose Your Desktop Environment"
echo "1. GNOME"
echo "2. KDE"
echo "3. XFCE"
echo "4. i3WM"
echo "5. NoDesktop"
read DESKTOP

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

criarArq(){
	echo "$1" > $2
}

forLength(){
    echo $1
    read txtForLength
    if [ "$txtForLength" = "" ]; then
            txtForLength=$3
            echo "Valor vazio, Default $txtForLength"
    elif [ "`expr length $txtForLength`" = $2 ]; then
            echo "Escolha $txtForLength"
    else
            txtForLength=$3
            echo "Necessario 6 digitos, Default $txtForLength"    
    fi
}

enableSystemctl(){
    echo "Ativar $1? [s]/[n]"
    read resp
    if [ "$resp" = "s" ]; then
        sudo systemctl enable $1
        sudo systemctl start $1 --now
    fi 
}

installPacotes(){
	echo -e "[INFO] - INSTALANDO PROGRAMAS - [INFO]"
	resp="vazio"
	clear
	echo "[INSTALAR PACOTES] 
Pacotes: $1	
Usar: [1]apt, [2]pacman [3]pamac [4]flatpak"
	read resp
	PROGRAMAS_PARA_INSTALAR=($1)
	for nome_do_programa in ${PROGRAMAS_PARA_INSTALAR[@]}; 
	do
		if [ "$resp" = 1 ]; then
			sudo apt --fix-broken install -y
	    	sudo apt install "$nome_do_programa" -y
		elif [ "$resp" = 2 ]; then
			sudo pacman -S "$nome_do_programa" --noconfirm
		elif [ "$resp" = 3 ]; then
			sudo pamac install "$nome_do_programa" --no-confirm
		elif [ "$resp" = 4 ]; then
			flatpak install "$nome_do_programa"
		fi
	done 
}

i3wmTouchpad(){
        sudo mkdir -p /etc/X11/xorg.conf.d && sudo tee <<'EOF' /etc/X11/xorg.conf.d/90-touchpad.conf 1> /dev/null
Section "InputClass"
        Identifier "touchpad"
        MatchIsTouchpad "on"
        Driver "libinput"
        Option "Tapping" "on"
EndSection

EOF
}

i3wmSetup(){
    installPacotes "i3 lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings pulseaudio pulseaudio-bluetooth samba xarchiver papirus-icon-theme breeze-gtk xcursor-comix ntfs-3g dosfstools os-prober gparted chromium nano git neofetch gufw gst-plugins-ugly gst-plugins-good gst-plugins-base gst-plugins-bad gst-libav gstreamer ffmpeg fwupd samba gvfs-smb flatpak gvfs gvfs-mtp gvfs-smb udisks2 polkit polkit-gnome net-tools bluez bluez-tools bluez-utils man-db font-manager gnu-free-fonts noto-fonts noto-fonts-cjk noto-fonts-emoji"
    enableSystemctl "lightdm"
    enableSystemctl "bluetooth"
    enableSystemctl "NetworkManager"
}

i3wmConfig(){
    #MAIN COLOR 005577, bfbfbf
    installPacotes "dmenu rofi i3lock i3status feh imagemagick nitrogen htop cmatrix acpilight volumeicon pcmanfm scrot xsel terminology lxrandr lxappearance xfce4-taskmanager xfce4-power-manager galculator system-config-printer blueman network-manager-applet pavucontrol"
    cp $HOME/.config/i3/config $HOME/.config/i3/config-bkp
    echo "[COLORS] Black:#000000, Gray:#808080, White:#FFFFFF"
    forLength "[COLOR] Bar" "7" "#000000"
    jrsbar=$txtForLength
    jrswindowtextosemfoco=$jrsbar
    forLength "[COLOR] Text" "7" "#ffffff"
    jrsbartexto=$txtForLength
    jrswindowtextocomfoco=$jrsbartexto
    forLength "[COLOR] Window" "7" "#005577"
    jrswindowcomfoco=$txtForLength
    jrswindowsemfoco="#7d7d7d"
    criarArq '######Jhonatanrs I3-WM config######
set $mod Mod4
set $textFont FreeMono 8
#set $appMenu dmenu_run
set $appMenu rofi -combi-modi drun#ssh#combi -show combi -window-title Rofi -scroll-method 1 -show-icons -combi-display-format "{text} ({mode})" -config $HOME/.config/i3/rofi.rasi 
set $appTerminal terminology
set $appFiles pcmanfm
set $appBrowser chromium
set $appF1 pavucontrol
set $appF2 galculator
set $appF3 xfce4-taskmanager
set $appF4 xfce4-power-manager-settings
set $appF5 lxrandr
set $appF6 lxappearance
set $appF7 nitrogen
set $appF8 system-config-printer
set $refresh_i3status killall -SIGUSR1 i3status
set $Locker i3lock -c 000000 -i $HOME/.config/i3/wallpaperI3Lock.png && sleep 1
set $ws1 "1"
set $ws2 "2"
set $ws3 "3"
set $ws4 "4"
set $ws5 "5"
set $ws6 "6"
set $ws7 "7"
set $ws8 "8"
set $ws9 "9"
set $ws10 "10"
set $tamanhodasbordas 3px
set $espacoentrejanelas 5px

###Font###
font pango:$textFont

###AutoStart###
exec --no-startup-id dex --autostart --environment i3
exec --no-startup-id xss-lock --transfer-sleep-lock -- i3lock --nofork
exec --no-startup-id nm-applet
exec --no-startup-id blueman-applet
#exec --no-startup-id volumeicon
exec --no-startup-id xfce4-power-manager
exec --no-startup-id nitrogen --restore
#exec --no-startup-id feh --bg-scale $HOME/.config/i3/wallpaperI3.png
exec --no-startup-id /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1

###Binds###
bindsym $mod+d exec --no-startup-id $appMenu
bindsym $mod+Return exec $appTerminal
bindsym $mod+Shift+Return exec i3-sensible-terminal
bindsym $mod+Shift+q kill
bindsym $mod+x exec $appFiles
bindsym $mod+c exec $appBrowser

###Print###
bindsym --release Print exec mkdir -p ~/PrtSc | scrot ~/PrtSc/creenshot_%Y-%m-%d_%H-%M-%S.png
bindsym --release $mod+Print exec mkdir -p ~/PrtSc | scrot -s ~/PrtSc/Cutshot_%Y-%m-%d_%H-%M-%S.png
bindsym --release $mod+z exec $HOME/.config/i3/getcol.sh

###Window###
bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right
bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Down move down
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Right move right
bindsym $mod+v split toggle
bindsym $mod+f fullscreen toggle
bindsym $mod+s layout stacking
bindsym $mod+w layout tabbed
bindsym $mod+e layout toggle split
bindsym $mod+Shift+space floating toggle
bindsym $mod+space focus mode_toggle
bindsym $mod+a focus parent
bindsym $mod+Shift+w sticky toggle

###Brightness and Sound###
bindsym XF86AudioRaiseVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +5% && $refresh_i3status
bindsym XF86AudioLowerVolume exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -5% && $refresh_i3status
bindsym XF86AudioMute exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && $refresh_i3status
bindsym XF86AudioMicMute exec --no-startup-id pactl set-source-mute @DEFAULT_SOURCE@ toggle && $refresh_i3status
#bindsym XF86MonBrightnessUp exec --no-startup-id light -A 5 && echo `light` > $HOME/.config/i3/brightness &&  $refresh_i3status
#bindsym XF86MonBrightnessDown exec --no-startup-id light -U 5 && echo `light` > $HOME/.config/i3/brightness  &&  $refresh_i3status
bindsym XF86MonBrightnessUp exec --no-startup-id xbacklight -dec 5 &&  $refresh_i3status
bindsym XF86MonBrightnessDown exec --no-startup-id xbacklight -inc 5 &&  $refresh_i3status

###Workspaces###
bindsym $mod+1 workspace number $ws1
bindsym $mod+2 workspace number $ws2
bindsym $mod+3 workspace number $ws3
bindsym $mod+4 workspace number $ws4
bindsym $mod+5 workspace number $ws5
bindsym $mod+6 workspace number $ws6
bindsym $mod+7 workspace number $ws7
bindsym $mod+8 workspace number $ws8
bindsym $mod+9 workspace number $ws9
bindsym $mod+0 workspace number $ws10
bindsym $mod+Shift+1 move container to workspace number $ws1
bindsym $mod+Shift+2 move container to workspace number $ws2
bindsym $mod+Shift+3 move container to workspace number $ws3
bindsym $mod+Shift+4 move container to workspace number $ws4
bindsym $mod+Shift+5 move container to workspace number $ws5
bindsym $mod+Shift+6 move container to workspace number $ws6
bindsym $mod+Shift+7 move container to workspace number $ws7
bindsym $mod+Shift+8 move container to workspace number $ws8
bindsym $mod+Shift+9 move container to workspace number $ws9
bindsym $mod+Shift+0 move container to workspace number $ws10
bindsym $mod+Shift+c reload
bindsym $mod+Shift+r restart
floating_modifier $mod

###i3Configs###
tiling_drag modifier titlebar
title_align center
hide_edge_borders none
default_border pixel $tamanhodasbordas
for_window [all] title_window_icon padding 5px
default_floating_border pixel $tamanhodasbordas
gaps inner $espacoentrejanelas
gaps outer 0px
smart_gaps off
workspace_layout default
for_window [class=$appTerminal] floating desable
for_window [title=$appF2] floating enable

###I3BARS###
bar {
	status_command i3status --config ~/.config/i3/i3status.conf
	position top
	mode dock
	#tray_output primary
        #tray_output HDMI-0
	tray_padding 2
	workspace_buttons yes
	workspace_min_width 25
	separator_symbol ":"
	strip_workspace_numbers yes
	strip_workspace_name no
	binding_mode_indicator yes
	padding 0 0 5 0
	colors {
	    #i3bar
	    background '$jrsbar'
	    statusline '$jrsbartexto'
	    separator '$jrsbartexto'
	    focused_workspace  '$jrswindowcomfoco' '$jrsbar' '$jrsbartexto'
	    active_workspace   '$jrsbar' '$jrsbar' '$jrsbartexto'
	    inactive_workspace '$jrsbar' '$jrsbar' '$jrsbartexto'
	    urgent_workspace   '$jrsbar' #900000 '$jrsbartexto'
       	    binding_mode       '$jrsbar' '$jrsbar' '$jrsbartexto'
    }
}
#class                  borda       background  texto         indicator   child_border
client.focused          '$jrswindowcomfoco' '$jrswindowcomfoco' '$jrswindowtextocomfoco' '$jrswindowcomfoco' '$jrswindowcomfoco'
client.focused_inactive '$jrswindowsemfoco' '$jrswindowsemfoco' '$jrswindowtextosemfoco' '$jrswindowsemfoco' '$jrswindowsemfoco'
client.unfocused        '$jrswindowsemfoco' '$jrswindowsemfoco' '$jrswindowtextosemfoco' '$jrswindowsemfoco' '$jrswindowsemfoco'
client.urgent           #2f343a #900000 #ffffff #900000 #900000
client.placeholder      #000000 #0c0c0c #ffffff #000000 #0c0c0c
client.background       #ffffff

###MODOS###
set $mode_programs [1/Sound][2/Calc][3/Tasks][4/Energy][5/Display][6/Looks][7/I3Paper][8/Printer]
mode "$mode_programs" {
    bindsym 1 exec $appF1, mode "default"
    bindsym 2 exec $appF2, mode "default"
    bindsym 3 exec $appF3, mode "default"
    bindsym 4 exec $appF4, mode "default"
    bindsym 5 exec $appF5, mode "default"
    bindsym 6 exec $appF6, mode "default"
    #bindsym 7 exec $appF7, mode "default"
    bindsym 7 exec $appF7 && convert -resize "$(xrandr | grep "*" | awk '"'"'{ print $1 }'"'"')!" -blur 0x10 $(cat .config/nitrogen/bg-saved.cfg | sed -n '"'"'2 p'"'"' | sed '"'"'s/file=//'"'"') $HOME/.config/i3/wallpaperI3Lock.png, mode "default"
    bindsym 8 exec $appF8, mode "default"
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+p mode "$mode_programs"

set $mode_sound [1/SoundUp][2/SoundDown][3/SoundMute][4/LightUp][5/LightDown]
mode "$mode_sound" {
    bindsym 1 exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ +5% && $refresh_i3status
    bindsym 2 exec --no-startup-id pactl set-sink-volume @DEFAULT_SINK@ -5% && $refresh_i3status
    bindsym 3 exec --no-startup-id pactl set-sink-mute @DEFAULT_SINK@ toggle && $refresh_i3status
    bindsym 4 exec --no-startup-id xbacklight -dec 5 &&  $refresh_i3status
    bindsym 5 exec --no-startup-id xbacklight -inc 5 &&  $refresh_i3status
    #bindsym 4 exec --no-startup-id light -A 5 && echo `light` > $HOME/.config/i3/brightness &&  $refresh_i3status
    #bindsym 5 exec --no-startup-id light -U 5 && echo `light` > $HOME/.config/i3/brightness  &&  $refresh_i3status
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+m mode "$mode_sound"

set $mode_system [1/Lock][2/Logout][3/Suspend][4/Hibernate][5/Reboot][6/Shutdown]
mode "$mode_system" {
    bindsym 1 exec --no-startup-id $Locker, mode "default"
    bindsym 2 exec --no-startup-id i3-msg exit, mode "default"
    bindsym 3 exec --no-startup-id $Locker && systemctl suspend, mode "default"
    bindsym 4 exec --no-startup-id $Locker && systemctl hibernate, mode "default"
    bindsym 5 exec --no-startup-id systemctl reboot, mode "default"
    bindsym 6 exec --no-startup-id systemctl poweroff -i, mode "default"  
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+Shift+e mode "$mode_system"

set $mode_resize [Resize]
mode "$mode_resize" {
        bindsym j resize shrink width 10 px or 10 ppt
        bindsym k resize grow height 10 px or 10 ppt
        bindsym l resize shrink height 10 px or 10 ppt
        bindsym ccedilla resize grow width 10 px or 10 ppt
        bindsym Left resize shrink width 10 px or 10 ppt
        bindsym Down resize grow height 10 px or 10 ppt
        bindsym Up resize shrink height 10 px or 10 ppt
        bindsym Right resize grow width 10 px or 10 ppt
        bindsym Return mode "default"
        bindsym Escape mode "default"
}
bindsym $mod+r mode "$mode_resize"
' "$HOME/.config/i3/config-jrsbkp.conf"

cd /proc/sys/net/ipv4/conf/
zerotierAdapter=$(echo zt*)

criarArq '# i3status configuration file.
# see "man i3status" for documentation.

# It is important that this file is edited as UTF-8.
# The following line should contain a sharp s:
# If the above line is not correctly displayed, fix your editor first!

general {
	colors = true
        interval = 5
	color_good = "'$jrsbartexto'"
	color_bad = "#FF0000"
	color_degraded = "#FFFF00"
}

order += "cpu_usage"
order += "memory"
order += "disk /"
order += "ethernet '$zerotierAdapter'"
order += "wireless _first_"
order += "ethernet _first_"
order += "volume master"
#order += "read_file BRIGHTNESS"
order += "battery all"
order += "tztime local"
#order += "tztime local1"

read_file BRIGHTNESS {
	format = "[☼/%content]"
	#path = "'$HOME'/.config/i3/brightness"
        path = "/sys/class/backlight/intel_backlight/brightness"
	max_characters = 5
	separator = false
	separator_block_width = 1
	align = "center"
        min_width = 1
}

cpu_usage {
	format = "[CPU/%usage]"
	max_threshold = 75
	separator = false
	separator_block_width = 1
	align = "center"
        min_width = 1
}

volume master {
	format = "[♪/%volume]"
	format_muted = "[♪/muted]"
	separator = false
	separator_block_width = 1
	align = "center"
        min_width = 1
}

wireless _first_ {
        format_up = "[W/%ip]"
	format_down = ""
	separator = false
	separator_block_width = 1
	align = "center"
        min_width = 1
}

ethernet _first_ {
        format_up = "[E/%ip]"
        format_down = ""
	separator = false
	separator_block_width = 1
	align = "center"
        min_width = 1
}

ethernet '$zerotierAdapter' {
        format_up = "[Z/%ip]"
        format_down = ""
	separator = false
	separator_block_width = 1
	align = "center"
        min_width = 1
        #diretorio com as redes /proc/sys/net/ipv4/conf/
}

battery all {
        format = "[%status/%percentage]"
        format_percentage = "%.00f%s"
        format_down = ""
	status_chr = "CHR"
        status_bat = "BAT"
        status_unk = "?"
	status_full = "FULL"
	separator = false
	separator_block_width = 1
	align = "center"
        min_width = 1
}

disk "/" {
        format = "[SSD/%used]"
	separator = false
	separator_block_width = 1
	align = "center"
        min_width = 1
}

load {
        format = "%1min"
}

memory {
        format = "[RAM/%used]"
        threshold_degraded = "1G"
        format_degraded = "[RAM/%used]"
	separator = false
	separator_block_width = 1
	align = "center"
        min_width = 1
}

tztime local {
        format = "[%a.%d %b %H:%M]"
        align = "right"
        min_width = 1
        separator = false
        separator_block_width = 1
}

tztime local1 {
        format = "[%d-%m-%Y %H:%M:%S]"
        align = "right"
        min_width = 1
        separator = false
        separator_block_width = 1
}


' "$HOME/.config/i3/i3status-jrsbkp.conf"

criarArq '
* {

    corcomfoco: '$jrswindowcomfoco';
    textocomfoco: '$jrswindowtextocomfoco';
    corsemfoco: '$jrswindowsemfoco';
    textosemfoco: '$jrswindowtextosemfoco';
    corbar: '$jrsbar';
    cortexto: '$jrsbartexto';
  
}

configuration {
    drun {
        display-name: "Desktop";
    }
    run {
        display-name: "Terminal";
    }
    ssh {
        display-name: "ssh";
    }
    window {
        display-name: "Program";
    }
    combi {
        display-name: " Search";
    }
}

window {
    background-color: @corbar;
    border-color: @corcomfoco;
    border:           3;
    padding:          0;
    width: 50%;
    height: 40%;
}
mainbox {
    border:  0;
    padding: 0;
}
message {
    border:       0px 0px 0px ;
    border-color: @corcomfoco;
    padding:      1px ;
}
textbox {
    text-color: @textocomfoco;
}
listview {
    fixed-height: 1;
    border:       0px 0px 0px ;
    border-color: @corcomfoco;
    spacing:      0px ;
    scrollbar:    true;
    padding:      0px 0px 10px 0px ;
}
element {
    border:  0;
    padding: 3px 10px 3px 10px ;
}
element-text {
    background-color: inherit;
    text-color:       inherit;
}
element.normal.normal {
    background-color: @corbar;
    text-color:       @textocomfoco;
}
element.normal.urgent {
    background-color: @corbar;
    text-color:       @textocomfoco;
}
element.normal.active {
    background-color: @corbar;
    text-color:       @corcomfoco;
}
element.selected.normal {
    background-color: @corcomfoco;
    text-color:       @textocomfoco;
}
element.selected.urgent {
    background-color: @corbar;
    text-color:       @textocomfoco;
}
element.selected.active {
    background-color: @corcomfoco;
    text-color:       @textocomfoco;
}
element.alternate.normal {
    background-color: @corbar;
    text-color:       @textocomfoco;
}
element.alternate.urgent {
    background-color: @corbar;
    text-color:       @textocomfoco;
}
element.alternate.active {
    background-color: @corbar;
    text-color:       @corcomfoco;
}
scrollbar {
    background-color: @cortexto;
    handle-color: @corsemfoco;
    width:        4px ;
    border:       0;
    handle-width: 3px;
    padding:      0;
}
mode-switcher {
    border:       2px 0px 0px ;
    border-color: @corcomfoco;
}
button.selected {
    background-color: @corbar;
    text-color:       @textocomfoco;
}
inputbar {
    spacing:    5;
    text-color: @textocomfoco;
    padding:    1px ;
}
case-indicator {
    spacing:    2;
    text-color: @textocomfoco;
}
entry {
    spacing:    2;
    text-color: @textocomfoco;
}
prompt {
    spacing:    2;
    text-color: @textocomfoco;
}
inputbar {
    border-color: @cortexto;
    border: 0px 0px 1px 0px;
    margin: 5px 10px 10px 10px;
    padding: 5px 0px 5px 0px;
    children:   [ prompt,textbox-prompt-colon,entry,case-indicator ];
}
textbox-prompt-colon {
    expand:     false;
    str:        ": ";
    margin:     0px ;
    text-color: @textocomfoco;
}

' "$HOME/.config/i3/rofi.rasi"

criarArq '#!/bin/sh
getcol=$(rm /tmp/getcol.png
        scrot -s /tmp/getcol.png
        convert /tmp/getcol.png \
	-define histogram:unique-colors=true \
	-format %c histogram:info:- | \
	sort -nr | \
	sed -n '"'""1s/[^#]*\([^ ]*\).*/\1/p""'"')
echo $getcol | xsel -bi
' "$HOME/.config/i3/getcol.sh"

        sudo chmod 777 $HOME/.config/i3/getcol.sh
        #sudo chmod +s /usr/bin/light
        mv $HOME/.config/i3/i3status-jrsbkp.conf $HOME/.config/i3/i3status.conf
        mv $HOME/.config/i3/config-jrsbkp.conf $HOME/.config/i3/config
        echo 'ACTION=="add", SUBSYSTEM=="backlight", RUN+="/bin/chgrp wheel $sys$devpath/brightness", RUN+="/bin/chmod g+w $sys$devpath/brightness"' | sudo tee /etc/udev/rules.d/backlight.rules
        #criarArq 'light' "$HOME/.config/i3/brightness"
        i3 restart
        sleep 0
}

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

