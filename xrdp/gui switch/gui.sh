#!/bin/bash
# GUI Switch for xRDP
# c 2020 sbroers
unset gui
unset GUI

while true
  do
    echo "Wählen Sie die GUI aus, die Sie für xRDP verwenden möchten:"
    echo ""
    echo "[1] Gnome 3"
    echo "[2] Xfce"
    echo "[3] KDE Plasma"
    echo "[4] MATE"
    echo "[5] Cinnamon"
    echo " "
    read -p "Eingabe:" gui

      case "$gui" in

        1) echo "gnome-session" > ~/.xsession
           GUI="Gnome 3"
           break ;;
        2) echo "startxfce4" > ~/.xsession
           GUI="Xfce"
           break ;;
        3) echo "startplasma-x11" > ~/.xsession
           GUI="KDE Plasma"
           break ;;
        4) echo "mate-session" > ~/.xsession
           GUI="MATE"
           break ;;
        5) echo "cinnamon" > ~/.xsession
           GUI="Cinnamon"
           break ;;
        *) echo " "
           echo "Geben Sie 1-5 ein! $gui ist eine ungültige Eingabe!"
           ;;
      esac
done

echo " "
echo "Die GUI: $GUI, wurde für xRDP eingestellt."
