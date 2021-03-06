#!/bin/bash
# enhanced-session-mode for debian 10.5

if [ "$(id -u)" -ne 0 ]; then
    echo 'Dieses Skript muss als root ausgeführt werden!' >&2
    exit 1
fi

# add backports repo
echo deb http://deb.debian.org/debian buster-backports main contrib non-free | tee /etc/apt/sources.list.d/buster-backports.list
apt update && apt upgrade -y
apt install -t buster-backports linux-image-amd64 -y
apt install -t buster-backports firmware-linux firmware-linux-nonfree -y

# install hyper-v daemons and activate them
apt install hyperv-daemons xorgxrdp -y

echo "# Hyper-V Modules" >> /etc/initramfs-tools/modules
echo "hv_vmbus" >> /etc/initramfs-tools/modules
echo "hv_storvsc" >> /etc/initramfs-tools/modules
echo "hv_blkvsc" >> /etc/initramfs-tools/modules
echo "hv_netvsc" >> /etc/initramfs-tools/modules
echo "hv_balloon" >> /etc/initramfs-tools/modules
echo "hv_utils" >> /etc/initramfs-tools/modules

cp -r /boot/efi/EFI/debian /boot/efi/EFI/BOOT
cp /boot/efi/EFI/BOOT/shimx64.efi /boot/efi/EFI/BOOT/bootx64.efi

export PATH=/sbin:$PATH

update-initramfs -u

# dirty way to use ubuntu packages instead of compile it from source
wget http://de.archive.ubuntu.com/ubuntu/pool/main/libj/libjpeg8-empty/libjpeg8_8c-2ubuntu8_amd64.deb
wget http://de.archive.ubuntu.com/ubuntu/pool/main/libj/libjpeg-turbo/libjpeg-turbo8_2.0.3-0ubuntu1_amd64.deb
wget http://de.archive.ubuntu.com/ubuntu/pool/universe/x/xrdp/xrdp_0.9.12-1_amd64.deb
dpkg -i *.deb

# Configure the installed XRDP ini files.
sed -i_orig -e 's/port=3389/port=vsock:\/\/-1:3389/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini
sed -i_orig -e 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini

# rename the redirected drives to 'shared-drives'
sed -i -e 's/FuseMountName=thinclient_drives/FuseMountName=Gemeinsame-Laufwerke/g' /etc/xrdp/sesman.ini

# activating normal user access
sed -i -e 's/TerminalServerUsers=tsusers/TerminalServerUsers=sudo/g' /etc/xrdp/sesman.ini
sed -i -e 's/TerminalServerAdmins=tsadmins/TerminalServerAdmins=sudo/g' /etc/xrdp/sesman.ini
sed -i -e 's/AlwaysGroupCheck=false/AlwaysGroupCheck=true/g' /etc/xrdp/sesman.ini
sed -i_orig -e 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config
/sbin/usermod -aG sudo $USER

# Logo
wget https://osdn.dl.osdn.net/linux-on-hyper-v/73546/debian.bmp
if [ -d "/usr/local/share/xrdp" ] 
then
    echo "Directory /path/to/dir exists." 
	sudo mv debian.bmp /usr/local/share/xrdp
    sudo sed -i 's/ls_logo_filename=/ls_logo_filename=\/usr\/local\/share\/xrdp\/debian.bmp/g' /etc/xrdp/xrdp.ini
else
    sudo mv debian.bmp /usr/share/xrdp
	sudo sed -i 's/ls_logo_filename=/ls_logo_filename=\/usr\/share\/xrdp\/debian.bmp/g' /etc/xrdp/xrdp.ini
fi

sudo sed -i 's/#ls_title=My Login Title/ls_title=Enter User and Password/' /etc/xrdp/xrdp.ini
sudo sed -i 's/ls_bg_color=dedede/ls_bg_color=ffffff/' /etc/xrdp/xrdp.ini
sudo sed -i 's/ls_logo_x_pos=55/ls_logo_x_pos=0/' /etc/xrdp/xrdp.ini
sudo sed -i 's/ls_logo_y_pos=50/ls_logo_y_pos=5/' /etc/xrdp/xrdp.ini

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
[Netowrkmanager]
Identity=unix-group:sudo
Action=org.freedesktop.NetworkManager.network-control
ResultAny=yes
ResultInactive=yes
ResultActive=yes
EOF

cat <<EOF | \
  sudo tee /etc/polkit-1/localauthority/50-local.d/xrdp-packagekit.pkla
[Netowrkmanager]
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
sudo apt-get install git libpulse-dev autoconf m4 intltool build-essential dpkg-dev libtool libsndfile-dev libcap-dev -y libjson-c-dev
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

# gui
wget "https://raw.githubusercontent.com/sbroers/linux-on-hyper-v/master/xrdp/gui%20switch/gui.sh"
chmod +x gui.sh
mv gui.sh /bin/gui
echo "gnome-session" >> /tmp/.xsession
cp /tmp/.xsession /home/*/
cp /tmp/.xsession /etc/skel/

# finish
clear
echo -e "\n"
echo -e "\033[1;36m *********************************************************************\033[0m"
echo -e "\033[1;36m *                 Installation abgeschlossen.                       *\033[0m"
echo -e "\033[1;36m *********************************************************************\033[0m"
echo -e "\033[1;36m * Geben Sie gui ein, um ihre Grafischeoberfläche für xRDP zu wählen.*\033[0m"
echo -e "\033[1;36m *                    (Standard ist Gnome)                           *\033[0m"
echo -e "\033[1;36m *                                                                   *\033[0m"
echo -e "\033[1;36m *    Bitte die VM herunterfahren und per PS den ESM aktivieren:     *\033[0m"
echo -e "\033[1;36m *   Set-VM -VMName “NAME“ -EnhancedSessionTransportType HvSocket    *\033[0m"
echo -e "\033[1;36m *********************************************************************\033[0m"
echo -e "\n"