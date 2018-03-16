#!/bin/bash

function blur {
    echo "Blurring the background"
    sleep 2
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'd = desktopForScreen(0); d.currentConfigGroup = Array("Wallpaper", "org.kde.image", "General"); print("cw=" + d.readConfig("Image"));'
    CURRENT_WP_PATH=$(journalctl -n 10 | grep -o 'cw=.*' | tail -n 1 | sed -E 's/cw=(file:\/\/)?//;s/"$//')
    convert -scale 10% -blur 0x5 -resize 1000% "$CURRENT_WP_PATH" ~/.bg.png
    echo "Background blurring finished"
}

if [ $(pidof -x wpblur.sh| wc -w) -gt 2 ]; then
	echo wpblur already running, exiting
    exit 1
fi

while true; do
    inotifywait -q ~/.config/plasma-org.kde.plasma.desktop-appletsrc -e delete_self | while read; do
        echo "~/.config/plasma-org.kde.plasma.desktop-appletsrc modified"
        blur
    done
done &

interface=org.kde.ActivityManager.Activities
member=CurrentActivityChanged

dbus-monitor --profile "interface='$interface',member='$member'" |
while read -r line; do
    if [[ $line = *"CurrentActivityChanged"* ]]; then
        echo "Activity changed"
        blur
    fi
done &

sleep infinity
