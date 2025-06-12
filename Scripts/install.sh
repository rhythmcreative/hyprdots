#!/usr/bin/env bash
#|---/ /+--------------------------+---/ /|#
#|--/ /-| Main installation script |--/ /-|#
#|-/ /--| Prasanth Rangan          |-/ /--|#
#|/ /---+--------------------------+/ /---|#

cat << "EOF"

-------------------------------------------------
        .
       / \         _       _  _      ___  ___ 
      /^  \      _| |_    | || |_  _|   \| __|
     /  _  \    |_   _|   | __ | || | |) | _| 
    /  | | ~\     |_|     |_||_|\_, |___/|___|
   /.-'   '-.\                  |__/          

-------------------------------------------------

EOF

#--------------------------------#
# import variables and functions #
#--------------------------------#
scrDir=$(dirname "$(realpath "$0")")
source "${scrDir}/global_fn.sh"
if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

#------------------#
# evaluate options #
#------------------#
flg_Install=0
flg_Restore=0
flg_Service=0

while getopts idrs RunStep; do
    case $RunStep in
        i)  flg_Install=1 ;;
        d)  flg_Install=1 ; export use_default="--noconfirm" ;;
        r)  flg_Restore=1 ;;
        s)  flg_Service=1 ;;
        *)  echo "...valid options are..."
            echo "i : [i]nstall hyprland without configs"
            echo "d : install hyprland [d]efaults without configs --noconfirm"
            echo "r : [r]estore config files"
            echo "s : enable system [s]ervices"
            exit 1 ;;
    esac
done

if [ $OPTIND -eq 1 ]; then
    flg_Install=1
    flg_Restore=1
    flg_Service=1
fi

#--------------------#
# pre-install script #
#--------------------#
if [ ${flg_Install} -eq 1 ] && [ ${flg_Restore} -eq 1 ]; then
    cat << "EOF"
                _         _       _ _
 ___ ___ ___   |_|___ ___| |_ ___| | |
| . |  _| -_|  | |   |_ -|  _| .'| | |
|  _|_| |___|  |_|_|_|___|_| |__,|_|_|
|_|

EOF

    "${scrDir}/install_pre.sh"
fi

#------------#
# installing #
#------------#
if [ ${flg_Install} -eq 1 ]; then
    cat << "EOF"

 _         _       _ _ _
|_|___ ___| |_ ___| | |_|___ ___
| |   |_ -|  _| .'| | | |   | . |
|_|_|_|___|_| |__,|_|_|_|_|_|_  |
                            |___|

EOF

    #----------------------#
    # prepare package list #
    #----------------------#
    shift $((OPTIND - 1))
    cust_pkg=$1
    cp "${scrDir}/custom_hypr.lst" "${scrDir}/install_pkg.lst"

    if [ -f "${cust_pkg}" ] && [ ! -z "${cust_pkg}" ]; then
        cat "${cust_pkg}" >> "${scrDir}/install_pkg.lst"
    fi

    if [ -f "${scrDir}/custom_apps.lst" ]; then
        cat "${scrDir}/custom_apps.lst" >> "${scrDir}/install_pkg.lst"
    fi

    #--------------------------------#
    # add nvidia drivers to the list #
    #--------------------------------#
    if nvidia_detect; then
        cat /usr/lib/modules/*/pkgbase | while read krnl; do
            echo "${krnl}-headers" >> "${scrDir}/install_pkg.lst"
        done
        nvidia_detect --drivers >> "${scrDir}/install_pkg.lst"
    fi

    nvidia_detect --verbose

    #----------------#
    # get user prefs #
    #----------------#
    if ! chk_list "aurhlpr" "${aurList[@]}"; then
        echo -e "Available aur helpers:\n[1] yay\n[2] yay (bin)\n[3] paru\n[4] paru (bin)"
        prompt_timer 120 "Enter option number [default: yay] "

        case "${promptIn}" in
            1) export getAur="yay" ;;
            2) export getAur="yay-bin" ;;
            3) export getAur="paru" ;;
            4) export getAur="paru-bin" ;;
            *) echo -e "...Invalid option selected..." ; exit 1 ;;
        esac
    fi

    if ! chk_list "myShell" "${shlList[@]}"; then
        echo -e "Select shell:\n[1] zsh\n[2] fish"
        prompt_timer 120 "Enter option number"

        case "${promptIn}" in
            1) export myShell="zsh" ;;
            2) export myShell="fish" ;;
            *) echo -e "...Invalid option selected..." ; exit 1 ;;
        esac
        echo "${myShell}" >> "${scrDir}/install_pkg.lst"
    fi

    #--------------------------------#
    # install packages from the list #
    #--------------------------------#
    "${scrDir}/install_pkg.sh" "${scrDir}/install_pkg.lst"
    rm "${scrDir}/install_pkg.lst"
    # Invoke the custom applications installer
    "${scrDir}/install_custom_apps.sh"
    
    # Install python-webcolors package
    echo -e "\n\033[0;32m[python-webcolors]\033[0m Installing python-webcolors..."
    sudo pacman -S python-webcolors --noconfirm || echo -e "\033[0;33m[SKIP]\033[0m python-webcolors may already be installed"
    
    #------------------------------#
    # detect ASUS laptop and ROG Control Center #
    #------------------------------#
    echo -e "\n\033[0;32m[ASUS Detection]\033[0m Checking for ASUS hardware..."
    
    # Check if it's an ASUS system
    if sudo dmidecode -s system-manufacturer 2>/dev/null | grep -i "asus" >/dev/null 2>&1 || \
       sudo dmidecode -s system-product-name 2>/dev/null | grep -i "rog\|tuf\|zenbook\|vivobook\|asus" >/dev/null 2>&1; then
        
        echo -e "\033[0;32m✓ ASUS system detected!\033[0m"
        echo -e "\033[0;33mDetected ASUS hardware. ROG Control Center provides:\033[0m"
        echo -e "  • RGB lighting control"
        echo -e "  • Fan curve management"
        echo -e "  • Performance profiles"
        echo -e "  • Aura sync support"
        echo ""
        
        # Ask user if they want to install ROG Control Center
        while true; do
            read -p "Do you want to install ROG Control Center? [Y/n]: " rog_choice
            case ${rog_choice:-Y} in
                [Yy]* )
                    echo -e "\033[0;32m[ROG Control Center]\033[0m Installing ROG Control Center..."
                    yay -S rog-control-center --noconfirm
                    if [ $? -eq 0 ]; then
                        echo -e "\033[0;32m✓ ROG Control Center installed successfully\033[0m"
                        echo -e "\033[0;33mTip: You can access it from the applications menu or run 'rog-control-center'\033[0m"
                    else
                        echo -e "\033[0;31m✗ Error installing ROG Control Center\033[0m"
                    fi
                    break
                    ;;
                [Nn]* )
                    echo -e "\033[0;33m[SKIP]\033[0m ROG Control Center installation skipped"
                    break
                    ;;
                * )
                    echo "Please answer yes (Y/y) or no (N/n)"
                    ;;
            esac
        done
    else
        echo -e "\033[0;33m[INFO]\033[0m Non-ASUS system detected, skipping ROG Control Center"
    fi
fi

#-----------------------------#
# install flatpak applications #
#-----------------------------#
echo -e "\n\033[0;32m[Flatpak]\033[0m Installing Flatpak applications..."
if [ -f "${scrDir}/.extra/install_fpk.sh" ]; then
    "${scrDir}/.extra/install_fpk.sh"
    if [ $? -eq 0 ]; then
        echo -e "\033[0;32m✓ Flatpak applications installed successfully\033[0m"
    else
        echo -e "\033[0;31m✗ Error installing Flatpak applications\033[0m"
    fi
else
    echo -e "\033[0;33m[SKIP]\033[0m Flatpak installer not found, skipping..."
fi

#---------------------------#
# restore my custom configs #
#---------------------------#
if [ ${flg_Restore} -eq 1 ]; then
    cat << "EOF"

             _           _
 ___ ___ ___| |_ ___ ___|_|___ ___
|  _| -_|_ -|  _| . |  _| |   | . |
|_| |___|___|_| |___|_| |_|_|_|_  |
                              |___|

EOF

    "${scrDir}/restore_fnt.sh"
    "${scrDir}/restore_cfg.sh"
    echo -e "\n\033[0;32m[themepatcher]\033[0m Patching themes..."
    while IFS='"' read -r null1 themeName null2 themeRepo
    do
        themeNameQ+=("${themeName//\"/}")
        themeRepoQ+=("${themeRepo//\"/}")
        themePath="${confDir}/hyde/themes/${themeName}"
        [ -d "${themePath}" ] || mkdir -p "${themePath}"
        [ -f "${themePath}/.sort" ] || echo "${#themeNameQ[@]}" > "${themePath}/.sort"
    done < "${scrDir}/themepatcher.lst"
    parallel --bar --link "${scrDir}/themepatcher.sh" "{1}" "{2}" "{3}" "{4}" ::: "${themeNameQ[@]}" ::: "${themeRepoQ[@]}" ::: "--skipcaching" ::: "false"
    echo -e "\n\033[0;32m[cache]\033[0m generating cache files..."
    "$HOME/.local/share/bin/swwwallcache.sh" -t ""
    if printenv HYPRLAND_INSTANCE_SIGNATURE &> /dev/null; then
        "$HOME/.local/share/bin/themeswitch.sh" &> /dev/null
    fi
fi

#--------------------------#
# clone BG-SDDM repository #
#--------------------------#
echo -e "\n\033[0;32m[BG-SDDM]\033[0m Clonando repositorio BG-SDDM..."
BG_SDDM_DIR="$HOME/BG-SDDM"
if [ ! -d "$BG_SDDM_DIR" ]; then
    git clone https://github.com/rhythmcreative/BG-SDDM "$BG_SDDM_DIR" && \
    echo -e "\033[0;32m[SUCCESS]\033[0m BG-SDDM clonado exitosamente en $BG_SDDM_DIR" || \
    echo -e "\033[0;31m[ERROR]\033[0m Error al clonar BG-SDDM"
else
    echo -e "\033[0;33m[SKIP]\033[0m BG-SDDM ya existe en $BG_SDDM_DIR"
fi

#---------------------#
# post-install script #
#---------------------#
if [ ${flg_Install} -eq 1 ] && [ ${flg_Restore} -eq 1 ]; then
    cat << "EOF"

             _      _         _       _ _
 ___ ___ ___| |_   |_|___ ___| |_ ___| | |
| . | . |_ -|  _|  | |   |_ -|  _| .'| | |
|  _|___|___|_|    |_|_|_|___|_| |__,|_|_|
|_|

EOF

    "${scrDir}/install_pst.sh"
    
    # Configure Sober with optimized settings
    echo -e "\n\033[0;32m[Sober]\033[0m Configurando Sober con ajustes optimizados..."
    if [ -f "${scrDir}/configure_sober.sh" ]; then
        "${scrDir}/configure_sober.sh"
    else
        echo -e "\033[0;33m[SKIP]\033[0m configure_sober.sh no encontrado, saltando configuración de Sober..."
    fi
fi

#------------------------#
# enable system services #
#------------------------#
if [ ${flg_Service} -eq 1 ]; then
    cat << "EOF"

                 _
 ___ ___ ___ _ _|_|___ ___ ___
|_ -| -_|  _| | | |  _| -_|_ -|
|___|___|_|  \_/|_|___|___|___|

EOF

    while read servChk; do

        if [[ $(systemctl list-units --all -t service --full --no-legend "${servChk}.service" | sed 's/^\s*//g' | cut -f1 -d' ') == "${servChk}.service" ]]; then
            echo -e "\033[0;33m[SKIP]\033[0m ${servChk} service is active..."
        else
            echo -e "\033[0;32m[systemctl]\033[0m starting ${servChk} system service..."
            sudo systemctl enable "${servChk}.service"
            sudo systemctl start "${servChk}.service"
        fi

    done < "${scrDir}/system_ctl.lst"
fi

#-------------------#
# enable/start sddm #
#-------------------#
echo -e "\n\033[0;32m[SDDM]\033[0m Habilitando e iniciando servicio SDDM..."
sudo systemctl enable sddm.service
sudo systemctl start sddm.service
echo -e "\033[0;32m[SUCCESS]\033[0m SDDM habilitado e iniciado exitosamente"
