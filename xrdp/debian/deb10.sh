# enhanced-session-mode debian 10.4

if [ "$(id -u)" -ne 0 ]; then
    echo 'This script must be run with root privileges' >&2
    exit 1
fi

# add backports repo

echo deb http://deb.debian.org/debian buster-backports main contrib non-free | sudo tee /etc/apt/sources.list.d/buster-backports.list
apt update

sudo apt install -t buster-backports linux-image-amd64
sudo apt install -t buster-backports firmware-linux firmware-linux-nonfree

# install hyper-v daemons and activate them

apt install hyperv-daemons

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

dpkg -i *

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

echo "Install is complete."
echo "Reboot your machine to begin using XRDP."
