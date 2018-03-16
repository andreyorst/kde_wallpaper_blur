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

if ! test -f "$BIN_PATH/journalctl" ; then
    echo journalctl not found on your system, please use systemd.
    exit
fi

qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'd = desktopForScreen(0); d.currentConfigGroup = Array("Wallpaper", "org.kde.image", "General"); print("cw=" + d.readConfig("Image"));'
CURRENT_WP_PATH=$(journalctl -n 10 | grep -o 'cw=.*' | tail -n 1 | sed -E 's/cw=(file:\/\/)?//;s/"$//')

if ! test -f ~/.bg.png; then
    if [ "$CURRENT_WP_PATH" ]; then
        echo blurring your current wallpaper
        echo
        convert -scale 10% -blur 0x5 -resize 1000% "$CURRENT_WP_PATH" ~/.bg.png
        sleep 10
    else
        PROMPT=1
        echo creating dummy .bg.png in $HOME
        echo
        touch ~/.bg.png
    fi
fi

SDDM_THEME_PATH=/usr/share/sddm/themes
SDDM_THEME=$(cat /etc/sddm.conf | grep 'Current' | sed -E 's/.*=//')

if ! [ $SDDM_THEME ]; then
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

echo creating sddm config
if [ ! -f $SDDM_THEME_PATH/theme.conf.user ]; then
    sudo cp theme.conf theme.conf.user
fi
cat $SDDM_THEME_PATH/theme.conf.user | sed -E 's/background=.*/background=.bg.png/' | sed -E 's/type=.*/type=image/' >> /tmp/theme.conf.user
sudo mv $SDDM_THEME_PATH/theme.conf.user $SDDM_THEME_PATH/theme.conf.user.prewpblur
sudo mv /tmp/theme.conf.user $SDDM_THEME_PATH/


echo generating kscreenlockerrc file
echo

KSCREENLOCKER=~/.config/kscreenlockerrc

if test -f ~/.config/kscreenlockerrc; then
    mv $KSCREENLOCKER $KSCREENLOCKER.prewpblur
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

cat <<EOF
Backups created:
$SDDM_THEME_PATH/theme.conf.user.prewpblur
$KSCREENLOCKER.prewpblur

EOF

if ! pgrep -x "wpblur.sh" > /dev/null; then
    echo starting script for current session
    $(pwd)/wpblur.sh &
fi

if [ $PROMPT ]; then
    echo now please change your wallpaper
else
    echo ready to use
fi
