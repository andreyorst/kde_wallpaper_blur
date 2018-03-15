#!/bin/bash

if [ $(pidof -x wpblur.sh| wc -w) -gt 2 ]; then
	echo wpblur already running, exiting
    exit 1
fi

while true; do
    inotifywait -q ~/.config/plasma-org.kde.plasma.desktop-appletsrc -e delete_self -e open | while read; do
        sleep 2
        qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'd = desktopForScreen(0); d.currentConfigGroup = Array("Wallpaper", "org.kde.image", "General"); print("cw=" + d.readConfig("Image"));'
        CURRENT_WP_PATH=$(journalctl -n 10 | grep -o 'cw=.*' | tail -n 1 | sed -E 's/cw=(file:\/\/)?//;s/"$//')
        convert "$CURRENT_WP_PATH" -filter Gaussian -resize 5% -define filter:sigma=2.5 -resize 2000% -attenuate 0.2 +noise Gaussian ~/.bg.png
    done
done
