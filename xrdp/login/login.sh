#!/bin/bash


#cd ~/Downloads
#cd $Dwnload
#cd /tmp
wget https://osdn.dl.osdn.net/linux-on-hyper-v/73077/griffon_logo_xrdp.bmp
unzip griffon_logo_xrdp.zip

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

#4F194C
# sudo sed -i 's/blue=009cb5/blue=dedede/' /etc/xrdp/xrdp.ini
# sudo sed -i 's/#white=ffffff/white=dedede/' /etc/xrdp/xrdp.ini
sudo sed -i 's/#ls_title=My Login Title/ls_title=Enter User and Password/' /etc/xrdp/xrdp.ini

# Background
# sudo sed -i 's/ls_top_window_bg_color=009cb5/ls_top_window_bg_color=4F194C/' /etc/xrdp/xrdp.ini

sudo sed -i 's/ls_bg_color=dedede/ls_bg_color=ffffff/' /etc/xrdp/xrdp.ini
sudo sed -i 's/ls_logo_x_pos=55/ls_logo_x_pos=0/' /etc/xrdp/xrdp.ini
sudo sed -i 's/ls_logo_y_pos=50/ls_logo_y_pos=5/' /etc/xrdp/xrdp.ini
