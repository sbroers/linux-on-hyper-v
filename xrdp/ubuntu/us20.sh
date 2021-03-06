#!/bin/bash
# enhanced-session-mode for ubuntu 20.04

if [ "$(id -u)" -ne 0 ]; then
    echo 'Dieses Skript muss mit root Rechten ausgeführt werden!' >&2
    exit 1
fi

# Install hv_kvp utils

sudo apt-add-repository -s 'deb http://de.archive.ubuntu.com/ubuntu/ focal main restricted'
sudo apt-add-repository -s 'deb http://de.archive.ubuntu.com/ubuntu/ focal restricted universe main multiverse'
sudo apt-add-repository -s 'deb http://de.archive.ubuntu.com/ubuntu/ focal-updates restricted universe main multiverse'
sudo apt-add-repository -s 'deb http://de.archive.ubuntu.com/ubuntu/ focal-backports main restricted universe multiverse'
sudo apt-add-repository -s 'deb http://de.archive.ubuntu.com/ubuntu/ focal-security main restricted universe main multiverse'

apt update && apt upgrade -y
apt install -y linux-tools-virtual
apt install -y linux-cloud-tools-virtual

# Install the xrdp service so we have the auto start behavior
apt install -y xrdp
systemctl stop xrdp
systemctl stop xrdp-sesman

# Configure the installed XRDP ini files.
sed -i_orig -e 's/port=3389/port=vsock:\/\/-1:3389/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/use_vsock=true/use_vsock=false/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini

# title screen & logo
wget https://osdn.dl.osdn.net/linux-on-hyper-v/73553/ubuntu.bmp
sudo cp ubuntu.bmp /usr/share/xrdp
sudo sed -i 's/ls_logo_filename=/ls_logo_filename=\/usr\/share\/xrdp\/ubuntu.bmp/g' /etc/xrdp/xrdp.ini
sudo sed -i 's/#ls_title=My Login Title/ls_title=Enter User and Password/' /etc/xrdp/xrdp.ini
sudo sed -i 's/ls_bg_color=dedede/ls_bg_color=ffffff/' /etc/xrdp/xrdp.ini
sudo sed -i 's/ls_logo_x_pos=55/ls_logo_x_pos=0/' /etc/xrdp/xrdp.ini
sudo sed -i 's/ls_logo_y_pos=50/ls_logo_y_pos=5/' /etc/xrdp/xrdp.ini

# rename the redirected drives to 'shared-drives'
sed -i -e 's/FuseMountName=thinclient_drives/FuseMountName=Gemeinsame-Laufwerke/g' /etc/xrdp/sesman.ini

# activating normal user access
sed -i -e 's/TerminalServerUsers=tsusers/TerminalServerUsers=sudo/g' /etc/xrdp/sesman.ini
sed -i -e 's/TerminalServerAdmins=tsadmins/TerminalServerAdmins=sudo/g' /etc/xrdp/sesman.ini
sed -i -e 's/AlwaysGroupCheck=false/AlwaysGroupCheck=true/g' /etc/xrdp/sesman.ini
sed -i_orig -e 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config

# Blacklist the vmw module
if [ ! -e /etc/modprobe.d/blacklist_vmw_vsock_vmci_transport.conf ]; then
cat >> /etc/modprobe.d/blacklist_vmw_vsock_vmci_transport.conf <<EOF
blacklist vmw_vsock_vmci_transport
EOF
fi

# Ensure hv_sock gets loaded
if [ ! -e /etc/modules-load.d/hv_sock.conf ]; then
echo "hv_sock" > /etc/modules-load.d/hv_sock.conf
fi

# Configure the policy xrdp session
cat > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla <<EOF
[Allow Colord all Users]
Identity=unix-group:sudo
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

cat <<EOF | \
sudo tee /etc/polkit-1/localauthority/50-local.d/xrdp-NetworkManager.pkla
[Networkmanager]
Identity=unix-group:sudo
Action=org.freedesktop.NetworkManager.network-control
ResultAny=yes
ResultInactive=yes
ResultActive=yes
EOF

cat <<EOF | \
sudo tee /etc/polkit-1/localauthority/50-local.d/xrdp-packagekit.pkla
[Networkmanager]
Identity=unix-group:sudo
Action=org.freedesktop.packagekit.system-sources-refresh
ResultAny=yes
ResultInactive=auth_admin
ResultActive=yes
EOF

# reconfigure the service
systemctl daemon-reload
systemctl start xrdp

# audio
sudo apt install git libpulse-dev autoconf m4 intltool build-essential dpkg-dev libtool libsndfile-dev libcap-dev libjson-c-dev -y
sudo apt build-dep pulseaudio -y

cd /tmp
sudo apt source pulseaudio

pulsever=$(pulseaudio --version | awk '{print $2}')
cd /tmp/pulseaudio-$pulsever
sudo ./configure

sudo git clone https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
cd pulseaudio-module-xrdp
sudo ./bootstrap 
sudo ./configure PULSE_DIR="/tmp/pulseaudio-$pulsever"
sudo make

cd /tmp/pulseaudio-$pulsever/pulseaudio-module-xrdp/src/.libs
sudo install -t "/var/lib/xrdp-pulseaudio-installer" -D -m 644 *.so
sudo install -t "/usr/lib/pulse-$pulsever/modules" -D -m 644 *.so
echo


sed -i "s/Exec=start-pulseaudio-x11/Exec=pulseaudio -k/" /etc/xdg/autostart/pulseaudio.desktop

wget "https://raw.githubusercontent.com/sbroers/linux-on-hyper-v/master/xrdp/gui%20switch/gui.sh"
chmod +x gui.sh
mv gui.sh /bin/gui

# gui gnomeubuntu
echo "export GNOME_SHELL_SESSION_MODE=ubuntu" > /tmp/.xsession
echo "export XDG_CURRENT_DESKTOP=ubuntu:GNOME" >> /tmp/.xsession
echo "gnome-session" >> /tmp/.xsession
cp /tmp/.xsession /home/*/
cp /tmp/.xsession /etc/skel/

# finish
clear
echo -e "\n"
echo -e "\033[1;36m *********************************************************************\033[0m"
echo -e "\033[1;36m *                 Installation abgeschlossen.                       *\033[0m"
echo -e "\033[1;36m *********************************************************************\033[0m"
echo -e "\033[1;36m * Geben Sie gui ein um ihre Grafischeoberfläche für xRDP zu wählen.*\033[0m"
echo -e "\033[1;36m *     (Standard ist Gnome, den Befehl als Benutzer ausführen!)      *\033[0m"
echo -e "\033[1;36m *                                                                   *\033[0m"
echo -e "\033[1;36m *    Bitte die VM herunterfahren und per PS den ESM aktivieren:     *\033[0m"
echo -e "\033[1;36m *   Set-VM -VMName “NAME“ -EnhancedSessionTransportType HvSocket    *\033[0m"
echo -e "\033[1;36m *********************************************************************\033[0m"
echo -e "\n"