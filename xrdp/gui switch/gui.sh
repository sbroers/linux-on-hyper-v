#!/bin/bash
# GUI Switch for xRDP
# c 2020 sbroers
unset gui
unset GUI

while true
  do
    echo "Wählen Sie die GUI aus, die Sie für xRDP verwenden möchten:"
    echo " "
    echo "[1] Gnome 3"
    echo "[2] Gnome Ubuntu"
    echo "[3] KDE Plasma"
    echo "[4] KDE Kubuntu"
    echo "[5] MATE"
    echo "[6] Cinnamon"
    echo "[7] Xfce"
    echo " "
    read -p "Eingabe:" gui

      case "$gui" in

        1) echo "gnome-session" > ~/.xsession
           GUI="Gnome 3"
           break ;;
        2) echo "export GNOME_SHELL_SESSION_MODE=ubuntu" > ~/.xsession
           echo "export XDG_CURRENT_DESKTOP=ubuntu:GNOME" >> ~/.xsession
           echo "gnome-session" >> ~/x.session
           GUI="Gnome-Ubuntu"      
           break ;;
        3) echo "startplasma-x11" > ~/.xsession
           GUI="KDE Plasma"
           break ;;
        4) echo "export XDG_DATA_DIRS=/usr/share/plasma:/usr/local/share:/usr/share:/var/lib/snapd/desktop" > ~/.xsession
           echo "export XDG_CONFIG_DIRS=/etc/xdg/xdg-plasma:/etc/xdg:/usr/share/kubuntu-default-settings/kf5-settings" >> ~/.xsession
           echo "export XDG_SESSION_DESKTOP=KDE"
           echo "startplasma-x11" >> ~/.xsession
           GUI="KDE Ubuntu"
           break ;;
        5) echo "mate-session" > ~/.xsession
           GUI="MATE"
           break ;;
        6) echo "cinnamon" > ~/.xsession
           GUI="Cinnamon"
           break ;;
        7) echo "startxfce4" > ~/.xsession
           GUI="Xfce"
           break ;;
        *) echo " "
           echo "Geben Sie 1-7 ein! $gui ist eine ungültige Eingabe!"
           ;;
      esac
done

echo " "
echo "Die GUI: $GUI, wurde für xRDP eingestellt."
