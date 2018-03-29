#!/bin/bash

# I AM BASH NOOB PLS DONT PUNCH ME HARD

BIN_PATH="/usr/bin"

if ! test -f "$BIN_PATH/inotifywait" ; then
    echo inotify-tools not found on your system, please install inotify-tools package.
    exit
fi

if ! test -f "$BIN_PATH/convert" ; then
    echo convert not found on your system, please install imagemagick package.
    exit
fi

curActivityId=$(qdbus org.kde.ActivityManager /ActivityManager/Activities CurrentActivity)
while read containmentId; do
    lastDesktop=$(kreadconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group $containmentId --key lastScreen)
    activityId=$(kreadconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group $containmentId --key activityId)
    if [[ $lastDesktop == "0" ]] && [[ $activityId == $curActivityId ]] ; then
        CURRENT_WP_PATH=$(kreadconfig5 --file ~/.config/plasma-org.kde.plasma.desktop-appletsrc --group Containments --group $containmentId --group Wallpaper --group org.kde.image --group General --key Image | sed -E 's/(file:\/\/)?//')
    fi
done <<< "$(grep -e '\[Containments]\[[0-9]*]\[Wallpaper]\[org.kde.image]\[General]' ~/.config/plasma-org.kde.plasma.desktop-appletsrc | sed 's/\[Containments\]\[//;s/]\[Wallpaper]\[org.kde.image]\[General]//')"

if ! test -f ~/.bg.png; then
    if [ "$CURRENT_WP_PATH" ]; then
        echo blurring your current wallpaper
        echo
        convert "$CURRENT_WP_PATH" -filter Gaussian -resize 5% -define filter:sigma=2.5 -resize 2000% -attenuate 0.2 +noise Gaussian ~/.bg.png
        sleep 10
    else
        PROMPT=1
        echo creating dummy .bg.png in $HOME
        echo
        touch ~/.bg.png
    fi
fi

SDDM_THEME_PATH=/usr/share/sddm/themes
if [[ -f /etc/sddm.conf ]]; then
    SDDM_THEME=$(grep 'Current=' /etc/sddm.conf | cut -f 2 -d '=')
else
    SDDM_THEME=''
fi

if [[ -z "$SDDM_THEME" ]]; then
    echo No theme found in /etc/sddm.conf
    echo You can find all theme names by executing $ ls $SDDM_THEME_PATH
    while true; do
        echo -n Please specify your theme name: ; read SDDM_THEME
        if ! test -d $SDDM_THEME_PATH/$SDDM_THEME; then
            echo No theme named $SDDM_THEME found at $SDDM_THEME_PATH/
        else
            break
        fi
    done
fi

SDDM_THEME_PATH=$SDDM_THEME_PATH/$SDDM_THEME

if ! test -f $SDDM_THEME_PATH/.bg.png; then
    echo creating symlink to .bg.png in $SDDM_THEME_PATH
    echo
    sudo ln -sf ~/.bg.png $SDDM_THEME_PATH/.bg.png
fi
sudo chmod 777 ~/.bg.png
setfacl -m u:sddm:x ~

if ! test -f $SDDM_THEME_PATH/theme.conf.user.prewpblur; then
    echo backuping sddm configuration files
    SDDM_BACKUP=1
    sudo mv $SDDM_THEME_PATH/theme.conf.user $SDDM_THEME_PATH/theme.conf.user.prewpblur
fi

echo creating sddm config
if [ ! -f $SDDM_THEME_PATH/theme.conf.user ]; then
    sudo cp $SDDM_THEME_PATH/theme.conf $SDDM_THEME_PATH/theme.conf.user
fi
cat $SDDM_THEME_PATH/theme.conf.user | sed -E 's/background=.*/background=.bg.png/' | sed -E 's/type=.*/type=image/' >> /tmp/theme.conf.user

# checking if backup exists
sudo mv /tmp/theme.conf.user $SDDM_THEME_PATH/

echo

KSCREENLOCKER=~/.config/kscreenlockerrc

if test -f ~/.config/kscreenlockerrc; then
    #checking for kscreenlockerrc backup
    if ! test -f $KSCREENLOCKER.prewpblur; then
        echo backuping kscreenlocker configuration files
        KSCREENLOCKER_BACKUP=1
        mv $KSCREENLOCKER $KSCREENLOCKER.prewpblur
    fi
    echo generating kscreenlockerrc file
    echo "[$Version]" > $KSCREENLOCKER
    echo $(grep "update_info" $KSCREENLOCKER.prewpblur) >> $KSCREENLOCKER
else
    echo "[$Version]" > $KSCREENLOCKER
    echo "update_info=kscreenlocker.upd:0.1-autolock" >> $KSCREENLOCKER
fi

cat <<EOF >> $KSCREENLOCKER

[Greeter]
WallpaperPlugin=org.kde.image

[Greeter][Wallpaper][org.kde.image][General]
FillMode=2
Image=file:///home/$USER/.bg.png
EOF

if ! test -d ~/.config/autostart-scripts; then
    mkdir ~/.config/autostart-scripts
fi

if test -f ~/.config/autostart-scripts/wpblur.sh; then
    rm ~/.config/autostart-scripts/wpblur.sh
fi

echo enabling script autostart
echo
ln -sf $(pwd)/wpblur.sh ~/.config/autostart-scripts/wpblur.sh
echo script will start automatically upon next login

if [[ $SDDM_BACKUP || $KSCREENLOCKER_BACKUP ]]; then
    echo
    echo backups created:
    if [[ $SDDM_BACKUP ]]; then
        echo $SDDM_THEME_PATH/theme.conf.user.prewpblur
    fi
    if [[ $KSCREENLOCKER_BACKUP ]]; then
        echo $KSCREENLOCKER.prewpblur
    fi
fi

if ! pgrep -x "wpblur.sh" > /dev/null; then
    echo
    echo starting script for current session
    $(pwd)/wpblur.sh &
fi

if [ $PROMPT ]; then
    echo
    echo now please change your wallpaper
else
    echo
    echo ready to use
fi
