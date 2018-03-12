#!/bin/bash

if [ $(pidof -x wpblur.sh | wc -w) -gt 2 ]; then
	echo wpblur already running, exiting
    exit 1
fi

SDDM_THEME_NAME=$(cat /etc/sddm.conf | grep 'Current' | sed -E 's/.*=//')
SDDM_THEME_PATH=/usr/share/sddm/themes/$SDDM_THEME_NAME

if ! [ $SDDM_THEME_NAME ]; then
cat <<EOF >> $HOME/.wpblur.log
$(date)
script terminated
reason: can't detrminate current SDDM theme path:
$SDDM_THEME_PATH/$SDDM_THEME_NAME/

EOF
exit 1
fi

while true; do
    inotifywait -q ~/.config/plasma-org.kde.plasma.desktop-appletsrc -e delete_self -e open | while read; do
        sleep 2
        convert "$(cat ~/.config/plasma-org.kde.plasma.desktop-appletsrc | grep -E "^Image=(file)?" | sed -E 's/Image=(file:\/\/)?//')" -filter Gaussian -resize 5% -define filter:sigma=2.5 -resize 2000% -attenuate 0.2 +noise Gaussian ~/.bg.png
        if test -w $SDDM_THEME_PATH/.bg.png; then
        cp ~/.bg.png $SDDM_THEME_PATH/.bg.png
        else
cat <<EOF >> $HOME/.wpblur.log
$(date)
script terminated
reason: can't overwrite $SDDM_THEME_PATH/.bg.png
check if file exists and have proper permissions.

EOF
exit 1
        fi
    done
done
