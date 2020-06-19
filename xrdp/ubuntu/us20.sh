#!/bin/bash

# Install hv_kvp utils
apt install -y linux-tools-virtual
apt install -y linux-cloud-tools-virtual

# Install the xrdp service so we have the auto start behavior
apt install -y xrdp

systemctl stop xrdp
systemctl stop xrdp-sesman

# Configure the installed XRDP ini files.
# use vsock transport.
sed -i_orig -e 's/port=3389/port=vsock:\/\/-1:3389/g' /etc/xrdp/xrdp.ini
# use rdp security.
sed -i_orig -e 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
# remove encryption validation.
sed -i_orig -e 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini
# disable bitmap compression since its local its much faster
sed -i_orig -e 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini

wget https://osdn.dl.osdn.net/linux-on-hyper-v/73077/griffon_logo_xrdp.bmp

#Check where to copy the logo file
if [ -d "/usr/local/share/xrdp" ] 
then
    echo "Directory /path/to/dir exists." 
	sudo cp griffon_logo_xrdp.bmp /usr/local/share/xrdp
    sudo sed -i 's/ls_logo_filename=/ls_logo_filename=\/usr\/local\/share\/xrdp\/griffon_logo_xrdp.bmp/g' /etc/xrdp/xrdp.ini
else
    sudo cp griffon_logo_xrdp.bmp /usr/share/xrdp
	sudo sed -i 's/ls_logo_filename=/ls_logo_filename=\/usr\/share\/xrdp\/griffon_logo_xrdp.bmp/g' /etc/xrdp/xrdp.ini
fi
sudo sed -i 's/#ls_title=My Login Title/ls_title=Enter User and Password/' /etc/xrdp/xrdp.ini

sudo sed -i 's/ls_bg_color=dedede/ls_bg_color=ffffff/' /etc/xrdp/xrdp.ini
sudo sed -i 's/ls_logo_x_pos=55/ls_logo_x_pos=0/' /etc/xrdp/xrdp.ini
sudo sed -i 's/ls_logo_y_pos=50/ls_logo_y_pos=5/' /etc/xrdp/xrdp.ini

# rename the redirected drives to 'shared-drives'
sed -i -e 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini

# activating normal user access
sed -i -e 's/TerminalServerUsers=tsusers/TerminalServerAdmins=sudo/g' /etc/xrdp/sesman.ini
sed -i -e 's/TerminalServerAdmins=tsadmins/TerminalServerAdmins=sudo/g' /etc/xrdp/sesman.ini
sed -i -e 's/AlwaysGroupCheck=false/AlwaysGroupCheck=true/g' /etc/xrdp/sesman.ini
addgroup tsusers

# Changed the allowed_users
sed -i_orig -e 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config

# Blacklist the vmw module
if [ ! -e /etc/modprobe.d/blacklist_vmw_vsock_vmci_transport.conf ]; then
cat >> /etc/modprobe.d/blacklist_vmw_vsock_vmci_transport.conf <<EOF
blacklist vmw_vsock_vmci_transport
EOF
fi

#Ensure hv_sock gets loaded
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

#########
# audio
#
sudo apt-add-repository -s 'deb http://de.archive.ubuntu.com/ubuntu/ focal main restricted'
sudo apt-add-repository -s 'deb http://de.archive.ubuntu.com/ubuntu/ focal restricted universe main multiverse'
sudo apt-add-repository -s 'deb http://de.archive.ubuntu.com/ubuntu/ focal-updates restricted universe main multiverse'
sudo apt-add-repository -s 'deb http://de.archive.ubuntu.com/ubuntu/ focal-backports main restricted universe multiverse'
sudo apt-add-repository -s 'deb http://de.archive.ubuntu.com/ubuntu/ focal-security main restricted universe main multiverse'
sudo apt-get update

# Step 2 - Install Some PreReqs
sudo apt-get install git libpulse-dev autoconf m4 intltool build-essential dpkg-dev libtool libsndfile-dev libcap-dev -y libjson-c-dev
sudo apt build-dep pulseaudio -y

# Step 3 -  Download pulseaudio source in /tmp directory - Do not forget to enable source repositories
cd /tmp
sudo apt source pulseaudio

# Step 4 - Compile
pulsever=$(pulseaudio --version | awk '{print $2}')
cd /tmp/pulseaudio-$pulsever
sudo ./configure

# step 5 - Create xrdp sound modules
sudo git clone https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
cd pulseaudio-module-xrdp
sudo ./bootstrap 
sudo ./configure PULSE_DIR="/tmp/pulseaudio-$pulsever"
sudo make

#Step 6 copy files to correct location (as defined in /etc/xrdp/pulse/default.pa)
cd /tmp/pulseaudio-$pulsever/pulseaudio-module-xrdp/src/.libs
sudo install -t "/var/lib/xrdp-pulseaudio-installer" -D -m 644 *.so
sudo install -t "/usr/lib/pulse-$pulsever/modules" -D -m 644 *.so
echo


sed -i "s/Exec=start-pulseaudio-x11/Exec=pulseaudio -k/" /etc/xdg/autostart/pulseaudio.desktop

wget "https://raw.githubusercontent.com/sbroers/linux-on-hyper-v/master/xrdp/gui%20switch/gui.sh"
chmod +x gui.sh
mv gui.sh /bin/gui
#

#
# End XRDP
###############################################################################

echo "Install is complete."
echo "Reboot your machine to begin using XRDP."
