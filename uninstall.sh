#!/bin/bash

BIN_PATH="/usr/bin"

if test -f ~/.bg.png; then
    UNINSTALL_PROMPT=1
    echo removing ~/.bg.png
    rm ~/.bg.png
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

if test -f $SDDM_THEME_PATH/.bg.png; then
    UNINSTALL_PROMPT=1
    echo removing $SDDM_THEME_PATH/.bg.png
    sudo rm $SDDM_THEME_PATH/.bg.png
fi

if [  -f $SDDM_THEME_PATH/theme.conf.user.prewpblur ]; then
    echo
    UNINSTALL_PROMPT=1
    echo restoring $SDDM_THEME_PATH/theme.conf.user from backup
    sudo mv $SDDM_THEME_PATH/theme.conf.user.prewpblur $SDDM_THEME_PATH/theme.conf.user
    echo
fi

KSCREENLOCKER=~/.config/kscreenlockerrc

if test -f ~/.config/kscreenlockerrc.prewpblur; then
    UNINSTALL_PROMPT=1
    echo restoring $KSCREENLOCKER from backup
    mv $KSCREENLOCKER.prewpblur $KSCREENLOCKER
    echo
fi

if test -f ~/.config/autostart-scripts/wpblur.sh; then
    echo
    UNINSTALL_PROMPT=1
    echo disabling script autostart
    rm ~/.config/autostart-scripts/wpblur.sh
fi

if pgrep -x "wpblur.sh" > /dev/null; then
    UNINSTALL_PROMPT=1
    echo killing existing script instances
    sudo pkill wpblur.sh
fi

if [[ $UNINSTALL_PROMPT ]]; then
    echo
    echo uninstalled succesfully
else
    echo nothing to do
fi
