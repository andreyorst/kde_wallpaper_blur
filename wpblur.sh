#!/bin/bash

function blur {
    echo "Blurring the background"
    sleep 2
    qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'd = desktopForScreen(0); d.currentConfigGroup = Array("Wallpaper", "org.kde.image", "General"); d.writeGlobalConfig("mainwp", d.readConfig("Image"));'
    CURRENT_WP_PATH=$(cat ~/.config/plasma-org.kde.plasma.desktop-appletsrc | grep -E "^mainwp=(file)?" | sed -E 's/mainwp=(file:\/\/)?//')
    convert "$CURRENT_WP_PATH" -filter Gaussian -resize 5% -define filter:sigma=2.5 -resize 2000% -attenuate 0.2 +noise Gaussian ~/.bg.png
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
