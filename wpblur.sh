#!/bin/bash
while true; do
    inotifywait -q ~/.config/plasma-org.kde.plasma.desktop-appletsrc -e delete_self -e open | while read; do
        convert $(cat ~/.config/plasma-org.kde.plasma.desktop-appletsrc | grep -E "^Image=(file)?" | sed -E 's/Image=(file:\/\/)?//') -filter Gaussian -resize 5% -define filter:sigma=2.5 -resize 2000% -attenuate 0.2 +noise Gaussian ~/.bg.png
        cp ~/.bg.png /usr/share/sddm/themes/$(cat /etc/sddm.conf | grep 'Current' | sed -E 's/.*=//')/.bg.png
    done
done
