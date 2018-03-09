#!/bin/bash

if [ $(pidof -x wpblur.sh| wc -w) -gt 2 ]; then
	echo wpblur already running, exiting
    exit 1
fi

while true; do
    inotifywait -q ~/.config/plasma-org.kde.plasma.desktop-appletsrc -e delete_self -e open | while read; do
        sleep 2
        convert "$(cat ~/.config/plasma-org.kde.plasma.desktop-appletsrc | grep -E "^Image=(file)?" | sed -E 's/Image=(file:\/\/)?//')" -filter Gaussian -resize 5% -define filter:sigma=2.5 -resize 2000% -attenuate 0.2 +noise Gaussian ~/.bg.png
    done
done
