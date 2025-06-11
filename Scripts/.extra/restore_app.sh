#!/usr/bin/env bash
#|---/ /+-----------------------------+---/ /|#
#|--/ /-| Script to configure my apps |--/ /-|#
#|-/ /--| Prasanth Rangan             |-/ /--|#
#|/ /---+-----------------------------+/ /---|#

scrDir=$(dirname "$(dirname "$(realpath "$0")")")
source "${scrDir}/global_fn.sh"
if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

cloneDir=$(dirname "$(realpath "$cloneDir")")


#// icons

if [ -f /usr/share/applications/rofi-theme-selector.desktop ] && [ -f /usr/share/applications/rofi.desktop ]; then
    sudo rm /usr/share/applications/rofi-theme-selector.desktop
    sudo rm /usr/share/applications/rofi.desktop
fi
sudo sed -i "/^Icon=/c\Icon=adjust-colors" /usr/share/applications/nwg-look.desktop
sudo sed -i "/^Icon=/c\Icon=spectacle" /usr/share/applications/swappy.desktop


#// librewolf

if pkg_installed librewolf-bin; then
    LibreRel=$(find ~/.librewolf -maxdepth 1 -type d -name "*.default" | head -1)

    if [ -z "${LibreRel}" ]; then
        librewolf &> /dev/null &
        sleep 1
        LibreRel=$(find ~/.librewolf -maxdepth 1 -type d -name "*.default" | head -1)
    else
        BkpDir="${HOME}/.config/cfg_backups/$(date +'%y%m%d_%Hh%Mm%Ss')_apps"
        mkdir -p "${BkpDir}"
        cp -r ~/.librewolf "${BkpDir}"
    fi

    # Note: LibreWolf uses its own profile structure, adapt configuration as needed
    # tar -xzf ${cloneDir}/Source/arcs/Firefox_UserConfig.tar.gz -C "${LibreRel}"
    # tar -xzf ${cloneDir}/Source/arcs/Firefox_Extensions.tar.gz -C ~/.librewolf/

    # find ~/.librewolf/extensions -maxdepth 1 -type f -name "*.xpi" | while read fext
    # do
    #     librewolf -profile "${LibreRel}" "${fext}" &> /dev/null &
    # done
fi

