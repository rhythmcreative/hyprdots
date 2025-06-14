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

#---------------------------#
# check unzip dependency   #
#---------------------------#
echo -e "\033[0;32m[DEPENDENCY CHECK]\033[0m Checking for required dependencies..."
if ! command -v unzip &> /dev/null; then
    echo -e "\033[0;33m[DEPENDENCY]\033[0m unzip is not installed. Installing unzip..."
    sudo pacman -S unzip --noconfirm --needed
    if [ $? -eq 0 ]; then
        echo -e "\033[0;32m[SUCCESS]\033[0m unzip installed successfully"
    else
        echo -e "\033[0;31m[ERROR]\033[0m Failed to install unzip. Please install it manually: sudo pacman -S unzip"
        exit 1
    fi
else
    echo -e "\033[0;32m[OK]\033[0m unzip is already installed"
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
    # ROG Control Center installation option #
    #------------------------------#
    echo -e "\n\033[0;32m[ROG Control Center]\033[0m ROG Control Center installation option"
    echo -e "\033[0;33mROG Control Center provides:\033[0m"
    echo -e "  • RGB lighting control"
    echo -e "  • Fan curve management"
    echo -e "  • Performance profiles"
    echo -e "  • Aura sync support"
    echo -e "  • Keyboard backlight control"
    echo ""
    
    # Ask user if they want to install ROG Control Center
    while true; do
        read -p "¿Deseas instalar ROG Control Center? [S/n]: " rog_choice
        case ${rog_choice:-S} in
            [SsYy]* )
                echo -e "\033[0;32m[ROG Control Center]\033[0m Instalando ROG Control Center..."
                echo -e "\033[0;33m[INFO]\033[0m Esto puede tomar unos minutos..."
                
                # Check if AUR helper is available
                if command -v yay &> /dev/null; then
                    yay -S rog-control-center --noconfirm
                elif command -v paru &> /dev/null; then
                    paru -S rog-control-center --noconfirm
                else
                    echo -e "\033[0;31m[ERROR]\033[0m No se encontró un helper de AUR (yay/paru)"
                    echo -e "\033[0;33m[INFO]\033[0m Intenta instalar manualmente: yay -S rog-control-center"
                    break
                fi
                
                if [ $? -eq 0 ]; then
                    echo -e "\033[0;32m✓ ROG Control Center instalado exitosamente\033[0m"
                    echo -e "\033[0;33m[ACCESO]\033[0m Puedes acceder desde:"
                    echo -e "  • Menú de aplicaciones"
                    echo -e "  • Terminal: \033[0;36mrog-control-center\033[0m"
                    echo -e "  • Super + R y escribir 'rog-control-center'"
                else
                    echo -e "\033[0;31m✗ Error al instalar ROG Control Center\033[0m"
                    echo -e "\033[0;33m[SOLUCIÓN]\033[0m Puedes instalarlo manualmente después con:"
                    echo -e "  \033[0;36myay -S rog-control-center\033[0m"
                fi
                break
                ;;
            [Nn]* )
                echo -e "\033[0;33m[OMITIDO]\033[0m Instalación de ROG Control Center omitida"
                echo -e "\033[0;33m[INFO]\033[0m Puedes instalarlo más tarde con: \033[0;36myay -S rog-control-center\033[0m"
                break
                ;;
            * )
                echo -e "\033[0;31mPor favor responde Sí (S/s) o No (N/n)\033[0m"
                ;;
        esac
    done
fi

#-----------------------------#
# install flatpak applications #
#-----------------------------#
echo -e "\n\033[0;32m[Flatpak]\033[0m Flatpak applications installer found."
echo -e "\033[0;33mFlatpak applications provide additional software like:\033[0m"
echo -e "  • Web browsers (Firefox, Chrome)"
echo -e "  • Media players (VLC, GNOME Videos)"
echo -e "  • Office suites (LibreOffice)"
echo -e "  • Development tools (VS Code, GIMP)"
echo ""

# Ask user if they want to install Flatpak applications
while true; do
    read -p "Do you want to install Flatpak applications? [Y/n]: " flatpak_choice
    case ${flatpak_choice:-Y} in
        [Yy]* )
            echo -e "\033[0;32m[Flatpak]\033[0m Installing Flatpak applications..."
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
            break
            ;;
        [Nn]* )
            echo -e "\033[0;33m[SKIP]\033[0m Flatpak applications installation skipped"
            break
            ;;
        * )
            echo "Please answer yes (Y/y) or no (N/n)"
            ;;
    esac
done

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

    "${scrDir}/install_svc.sh"
fi



#-------------------------------#
# Create Setup-Errores folder   #
#-------------------------------#
echo -e "\n\033[0;32m[Setup-Errores]\033[0m Creando carpeta Setup-Errores..."
mkdir -p ~/Downloads/Setup-Errores
echo -e "\033[0;32m[SUCCESS]\033[0m Carpeta Setup-Errores creada en ~/Downloads/"

echo -e "\n\033[0;32m[Setup-Errores]\033[0m Copiando scripts de instalación..."
cp "/home/$(whoami)/hyprdots/Scripts/install_mysql_workbench.sh" ~/Downloads/Setup-Errores/
cp "/home/$(whoami)/hyprdots/Scripts/fix_hyprland_conf.sh" ~/Downloads/Setup-Errores/
cp "/home/$(whoami)/hyprdots/Scripts/configure_sober.sh" ~/Downloads/Setup-Errores/
echo -e "\033[0;32m[SUCCESS]\033[0m Scripts copiados a ~/Downloads/Setup-Errores/"
echo -e "\033[0;33m[INFO]\033[0m Archivos disponibles en la carpeta Setup-Errores:"
ls -la ~/Downloads/Setup-Errores/

#--------------#
# Final report #
#--------------#
echo -e "\n\033[0;36m┌─────────────────────────────────────────────────┐\033[0m"
echo -e "\033[0;36m│               Installation Complete             │\033[0m"
echo -e "\033[0;36m└─────────────────────────────────────────────────┘\033[0m"
echo -e "\n\033[0;32m[COMPLETE]\033[0m ¡Instalación de HyprDots completada!"
echo -e "\033[0;33m[NEXT]\033[0m Reinicia tu sistema para aplicar todos los cambios"
echo -e "\033[0;33m[INFO]\033[0m Comandos útiles después del reinicio:"
echo -e "  - \033[0;36mhyprctl reload\033[0m: Recargar configuración de Hyprland"
echo -e "  - \033[0;36mwaybar &\033[0m: Iniciar waybar manualmente"
echo -e "  - \033[0;36mthemepatcher.sh\033[0m: Cambiar temas"
echo -e "  - \033[0;36m./Scripts/install_grub_theme.sh uninstall\033[0m: Desinstalar tema GRUB"


#-------------------#
# enable/start sddm #
#-------------------#
echo -e "\n\033[0;32m[SDDM]\033[0m Habilitando e iniciando servicio SDDM..."
sudo systemctl enable sddm.service
sudo systemctl start sddm.service
echo -e "\033[0;32m[SUCCESS]\033[0m SDDM habilitado e iniciado exitosamente"

