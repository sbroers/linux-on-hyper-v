#!/bin/bash

sudo yum install xrdp xorgxrdp

# Configure the installed XRDP ini files.
# use vsock transport.
sed -i_orig -e 's/port=3389/port=vsock:\/\/-1:3389/g' /etc/xrdp/xrdp.ini
# use rdp security.
sed -i_orig -e 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
# remove encryption validation.
sed -i_orig -e 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini
# disable bitmap compression since its local its much faster
sed -i_orig -e 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini

# rename the redirected drives to 'shared-drives'
sed -i -e 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini

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
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

# Audio Install
sudo yum groupinstall "Development Tools"
sudo yum install libcap-devel.x86_64 pulseaudio-libs-devel.x86_64 libsndfile-devel.x86_64 libcap-devel.x86_64 jansson.x86_64 
sudo yum install rpmdevtools yum-utils
sudo rpmdev-setuptree
sudo dnf builddep pulseaudio -y

yumdownloader --source pulseaudio
rpm --install pulseaudio*.src.rpm

pulseaudio --version > /tmp/p123
sed -i -e 's/-rebootstrapped//g' /tmp/p123
sed -i -e 's/pulseaudio //g' /tmp/p123
pulsever=$(cat /tmp/p123)
PULSE_DIR=~/rpmbuild/BUILD/pulseaudio-$pulsever
git clone https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
cd pulseaudio-module-xrdp
./bootstrap && ./configure PULSE_DIR=~/rpmbuild/BUILD/pulseaudio-$pulsever
make

rpmbuild -bb --noclean ~/rpmbuild/SPECS/pulseaudio.spec
make
make install

# reconfigure the service
sudo systemctl enable xrdp
sudo systemctl enable xrdp-sesman
sudo systemctl daemon-reload
sudo systemctl start xrdp
sudo systemctl start xrdp-sesman



echo "Install is complete."
echo "Reboot your machine to begin using XRDP."
