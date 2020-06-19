# enhanced-session-mode kali 2020.02

# add backports repo
echo deb http://deb.debian.org/debian buster-backports main contrib non-free | sudo tee /etc/apt/sources.list.d/buster-backports.list
sudo apt update -y

sudo apt install -t buster-backports linux-image-amd64 -y
sudo apt install -t buster-backports firmware-linux firmware-linux-nonfree -y

# install hyper-v daemons and activate them

sudo apt install hyperv-daemons xrdp xorgxrdp -y

echo "# Hyper-V Modules" >> /etc/initramfs-tools/modules
echo "hv_vmbus" >> /etc/initramfs-tools/modules
echo "hv_storvsc" >> /etc/initramfs-tools/modules
echo "hv_blkvsc" >> /etc/initramfs-tools/modules
echo "hv_netvsc" >> /etc/initramfs-tools/modules
echo "hv_balloon" >> /etc/initramfs-tools/modules
echo "hv_utils" >> /etc/initramfs-tools/modules

sudo mkdir /boot/efi/EFI/BOOT
wget https://github.com/sbroers/linux-on-hyper-v/blob/master/efi/BOOTx64.EFI
sudo mv BOOTx64.EFI /boot/efi/EFI/BOOT 

sudo export PATH=/sbin:$PATH

sudo update-initramfs -u

# Configure the installed XRDP ini files.
# use vsock transport.
sudo sed -i_orig -e 's/port=3389/port=vsock:\/\/-1:3389/g' /etc/xrdp/xrdp.ini
# use rdp security.
sudo sed -i_orig -e 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini
# remove encryption validation.
sudo sed -i_orig -e 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini
# disable bitmap compression since its local its much faster
sudo sed -i_orig -e 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini

# rename the redirected drives to 'shared-drives'
sudo sed -i -e 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini

# Changed the allowed_users
sudo sed -i_orig -e 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config

# Blacklist the vmw module
if [ ! -e /etc/modprobe.d/blacklist_vmw_vsock_vmci_transport.conf ]; then
sudo cat >> /etc/modprobe.d/blacklist_vmw_vsock_vmci_transport.conf <<EOF
blacklist vmw_vsock_vmci_transport
EOF
fi

#Ensure hv_sock gets loaded
if [ ! -e /etc/modules-load.d/hv_sock.conf ]; then
sudo echo "hv_sock" > /etc/modules-load.d/hv_sock.conf
fi

# Configure the policy xrdp session
sudo cat > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla <<EOF
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

# fix missing xrdp.ini
sudo cp /etc/xrdp/xrdp.ini_orig /etc/xrdp/xrdp.ini

# reconfigure the service

sudo systemctl enable xrdp
sudo systemctl enable xrdp-sesman
sudo systemctl daemon-reload
sudo systemctl start xrdp

echo "Install is complete."
echo "Reboot your machine to begin using XRDP."
