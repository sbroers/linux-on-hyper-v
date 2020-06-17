#!/bin/bash

# GUI Switch for xRDP

echo "Wählen Sie die GUI aus, die Sie für xRDP verwenden möchten:"
echo "[1] Gnome 3"
echo "[2] Xfce"
echo "[3] KDE"
echo "[4] MATE"
echo "[5] Cinnamon"
echo "[6] LXDE"

read -p "Eingabe:" gui

case "$gui" in

     1) echo "gnome-session" > ~/.xsession
     ;;
     2) echo "startxfce4" > ~/.xsession
     ;;
     3) echo "startplasma-x11" > ~/.xsession
     ;;
     4) echo "mate-session" > ~/.xsession
     ;;
     5) echo "cinnamon" > ~/.xsession
     ;;
     6) echo "startlxde" > ~/.xsession
     ;;
esac

echo "Die gewählte GUI, wurde für xRDP eingestellt."
