#!/bin/bash

function currentWpPath {
    curActivityId=$(qdbus org.kde.ActivityManager /ActivityManager/Activities CurrentActivity)
    while read containmentId; do 
        lastDesktop=$(kreadconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group $containmentId --key lastScreen)
        activityId=$(kreadconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group $containmentId --key activityId)
        if [[ $lastDesktop == "0" ]] && [[ $activityId == $curActivityId ]] ; then
            CURRENT_WP_PATH=$(kreadconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group $containmentId --group Wallpaper --group org.kde.image --group General --key Image | sed -E 's/(file:\/\/)?//')
        fi
    done <<< "$(grep -e '\[Containments]\[[0-9]*]\[Wallpaper]\[org.kde.image]\[General]' ~/.config/plasma-org.kde.plasma.desktop-appletsrc | sed 's/\[Containments\]\[//;s/]\[Wallpaper]\[org.kde.image]\[General]//')" 
    echo "$CURRENT_WP_PATH"
}

function blurWp {
    CURRENT_WP_PATH="$1"
    echo "Blurring the background"
    convert "$CURRENT_WP_PATH" -filter Gaussian -resize 5% -define filter:sigma=2.5 -resize 2000% -attenuate 0.2 +noise Gaussian ~/.bg.png
    echo "Background blurring finished"
}

function blur {
    CURRENT_WP_PATH=$(currentWpPath)
    blurWp "$CURRENT_WP_PATH"
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
