#!/usr/bin/env bash
#|---/ /+-------------------------------------+---/ /|#
#|--/ /-| Script to apply pre install configs |--/ /-|#
#|-/ /--| Prasanth Rangan                     |-/ /--|#
#|/ /---+-------------------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
source "${scrDir}/global_fn.sh"
if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

# grub
if pkg_installed grub && [ -f /boot/grub/grub.cfg ]; then
    echo -e "\033[0;32m[BOOTLOADER]\033[0m detected // grub"

    if [ ! -f /etc/default/grub.t2.bkp ] && [ ! -f /boot/grub/grub.t2.bkp ]; then
        echo -e "\033[0;32m[BOOTLOADER]\033[0m configuring grub..."
        sudo cp /etc/default/grub /etc/default/grub.t2.bkp
        sudo cp /boot/grub/grub.cfg /boot/grub/grub.t2.bkp

        if nvidia_detect; then
            echo -e "\033[0;32m[BOOTLOADER]\033[0m nvidia detected, adding nvidia_drm.modeset=1 to boot option..."
            gcld=$(grep "^GRUB_CMDLINE_LINUX_DEFAULT=" "/etc/default/grub" | cut -d'"' -f2 | sed 's/\b nvidia_drm.modeset=.\b//g')
            sudo sed -i "/^GRUB_CMDLINE_LINUX_DEFAULT=/c\GRUB_CMDLINE_LINUX_DEFAULT=\"${gcld} nvidia_drm.modeset=1\"" /etc/default/grub
        fi

        # Detect LUKS encryption and configure GRUB accordingly
        if lsblk -f | grep -q "crypto_LUKS" || [ -f /etc/crypttab ]; then
            echo -e "\033[0;32m[BOOTLOADER]\033[0m LUKS encryption detected, configuring GRUB for encrypted boot..."
            
            # Enable cryptodisk support
            if ! grep -q "^GRUB_ENABLE_CRYPTODISK=y" /etc/default/grub; then
                echo "GRUB_ENABLE_CRYPTODISK=y" | sudo tee -a /etc/default/grub
            fi
            
            # Set appropriate timeout for password entry
            sudo sed -i "/^GRUB_TIMEOUT=/c\GRUB_TIMEOUT=10" /etc/default/grub
            sudo sed -i "/^#GRUB_TIMEOUT=/c\GRUB_TIMEOUT=10" /etc/default/grub
            
            # Ensure proper video mode for theme display with LUKS
            sudo sed -i "/^GRUB_GFXPAYLOAD_LINUX=/c\GRUB_GFXPAYLOAD_LINUX=keep" /etc/default/grub
            sudo sed -i "/^#GRUB_GFXPAYLOAD_LINUX=/c\GRUB_GFXPAYLOAD_LINUX=keep" /etc/default/grub
            
            echo -e "\033[0;32m[BOOTLOADER]\033[0m LUKS configuration applied for proper theme support"
        fi

        echo -e "Select grub theme:\n[1] Retroboot (dark)\n[2] Pochita (light)\n[3] Hyperfluent-arch (modern)"
        read -p " :: Press enter to skip grub theme <or> Enter option number : " grubopt
        case ${grubopt} in
            1) grubtheme="Retroboot" ;;
            2) grubtheme="Pochita" ;;
            3) grubtheme="hyperfluent-arch" ;;
            *) grubtheme="None" ;;
        esac

        if [ "${grubtheme}" == "None" ]; then
            echo -e "\033[0;32m[BOOTLOADER]\033[0m Skipping grub theme..."
            sudo sed -i "s/^GRUB_THEME=/#GRUB_THEME=/g" /etc/default/grub
        elif [ "${grubtheme}" == "hyperfluent-arch" ]; then
            echo -e "\033[0;32m[BOOTLOADER]\033[0m Installing hyperfluent-arch theme using dedicated installer..."
            
            # Use the dedicated install_grub_theme.sh script for hyperfluent-arch
            if [ -f "${scrDir}/install_grub_theme.sh" ]; then
                "${scrDir}/install_grub_theme.sh" install
                if [ $? -eq 0 ]; then
                    echo -e "\033[0;32m[SUCCESS]\033[0m Hyperfluent-arch theme installed successfully"
                    grubtheme="hyperfluent-arch"
                else
                    echo -e "\033[0;31m[ERROR]\033[0m Failed to install hyperfluent-arch theme"
                    grubtheme="None"
                fi
            else
                echo -e "\033[0;31m[ERROR]\033[0m install_grub_theme.sh not found, falling back to manual installation"
                # Fallback to manual installation
                local theme_file="${cloneDir}/Source/arcs/hyperfluent-arch.tar.gz"
                if [ -f "$theme_file" ]; then
                    echo -e "\033[0;32m[BOOTLOADER]\033[0m Installing theme manually..."
                    sudo mkdir -p /usr/share/grub/themes/
                    
                    # Check if it's actually a ZIP file
                    if file "$theme_file" | grep -q "Zip archive"; then
                        echo -e "\033[0;32m[BOOTLOADER]\033[0m Extracting ZIP format theme..."
                        local temp_dir="/tmp/grub-theme-extract"
                        sudo rm -rf "$temp_dir"
                        sudo mkdir -p "$temp_dir"
                        sudo unzip -q "$theme_file" -d "$temp_dir"
                        sudo cp -r "$temp_dir"/* "/usr/share/grub/themes/${grubtheme}/"
                        sudo rm -rf "$temp_dir"
                    else
                        sudo tar -xzf "$theme_file" -C /usr/share/grub/themes/
                    fi
                    
                    # Configure GRUB manually
                    sudo sed -i "/^GRUB_THEME=/c\GRUB_THEME=\"/usr/share/grub/themes/${grubtheme}/theme.txt\"" /etc/default/grub
                    sudo sed -i "/^#GRUB_THEME=/c\GRUB_THEME=\"/usr/share/grub/themes/${grubtheme}/theme.txt\"" /etc/default/grub
                else
                    echo -e "\033[0;31m[ERROR]\033[0m Theme file not found: $theme_file"
                    grubtheme="None"
                fi
            fi
        else
            echo -e "\033[0;32m[BOOTLOADER]\033[0m Setting grub theme // ${grubtheme}"
            
            # Traditional naming for other themes (Retroboot, Pochita)
            sudo tar -xzf ${cloneDir}/Source/arcs/Grub_${grubtheme}.tar.gz -C /usr/share/grub/themes/
            
            # Configure GRUB with theme settings optimized for LUKS
            sudo sed -i "/^GRUB_DEFAULT=/c\GRUB_DEFAULT=saved" /etc/default/grub
            sudo sed -i "/^GRUB_GFXMODE=/c\GRUB_GFXMODE=1920x1080x32,1280x1024x32,auto" /etc/default/grub
            sudo sed -i "/^#GRUB_GFXMODE=/c\GRUB_GFXMODE=1920x1080x32,1280x1024x32,auto" /etc/default/grub
            sudo sed -i "/^GRUB_THEME=/c\GRUB_THEME=\"/usr/share/grub/themes/${grubtheme}/theme.txt\"" /etc/default/grub
            sudo sed -i "/^#GRUB_THEME=/c\GRUB_THEME=\"/usr/share/grub/themes/${grubtheme}/theme.txt\"" /etc/default/grub
            sudo sed -i "/^#GRUB_SAVEDEFAULT=true/c\GRUB_SAVEDEFAULT=true" /etc/default/grub
            
            # Universal settings for theme compatibility
            if ! grep -q "^GRUB_TERMINAL=" /etc/default/grub; then
                echo "GRUB_TERMINAL=gfxterm" | sudo tee -a /etc/default/grub
            else
                sudo sed -i "/^GRUB_TERMINAL=/c\GRUB_TERMINAL=gfxterm" /etc/default/grub
            fi

            # Configure video settings for optimal theme display
            sudo sed -i "/^GRUB_GFXPAYLOAD_LINUX=/c\GRUB_GFXPAYLOAD_LINUX=keep" /etc/default/grub
            sudo sed -i "/^#GRUB_GFXPAYLOAD_LINUX=/c\GRUB_GFXPAYLOAD_LINUX=keep" /etc/default/grub

            # Check if LUKS is present and apply additional optimizations
            if lsblk -f | grep -q "crypto_LUKS" || [ -f /etc/crypttab ]; then
                echo -e "\033[0;32m[BOOTLOADER]\033[0m LUKS detected - Theme configured with encryption optimizations"
                # Ensure timeout is adequate for password entry
                if ! grep -q "^GRUB_TIMEOUT=" /etc/default/grub; then
                    echo "GRUB_TIMEOUT=10" | sudo tee -a /etc/default/grub
                else
                    sudo sed -i "/^GRUB_TIMEOUT=/c\GRUB_TIMEOUT=10" /etc/default/grub
                fi
            else
                echo -e "\033[0;32m[BOOTLOADER]\033[0m Standard system - Theme configured for optimal performance"
                # Standard timeout for non-encrypted systems
                if ! grep -q "^GRUB_TIMEOUT=" /etc/default/grub; then
                    echo "GRUB_TIMEOUT=5" | sudo tee -a /etc/default/grub
                else
                    sudo sed -i "/^GRUB_TIMEOUT=/c\GRUB_TIMEOUT=5" /etc/default/grub
                fi
            fi
        fi

        # Only regenerate GRUB config if theme was not installed by dedicated script
        if [ "${grubtheme}" != "hyperfluent-arch" ] || [ ! -f "${scrDir}/install_grub_theme.sh" ]; then
            sudo grub-mkconfig -o /boot/grub/grub.cfg
        else
            echo -e "\033[0;32m[BOOTLOADER]\033[0m GRUB config already regenerated by dedicated installer"
        fi
    else
        echo -e "\033[0;33m[SKIP]\033[0m grub is already configured..."
    fi
fi

# systemd-boot
if pkg_installed systemd && nvidia_detect && [ $(bootctl status 2> /dev/null | awk '{if ($1 == "Product:") print $2}') == "systemd-boot" ]; then
    echo -e "\033[0;32m[BOOTLOADER]\033[0m detected // systemd-boot"

    if [ $(ls -l /boot/loader/entries/*.conf.t2.bkp 2> /dev/null | wc -l) -ne $(ls -l /boot/loader/entries/*.conf 2> /dev/null | wc -l) ]; then
        echo "nvidia detected, adding nvidia_drm.modeset=1 to boot option..."
        find /boot/loader/entries/ -type f -name "*.conf" | while read imgconf; do
            sudo cp ${imgconf} ${imgconf}.t2.bkp
            sdopt=$(grep -w "^options" ${imgconf} | sed 's/\b quiet\b//g' | sed 's/\b splash\b//g' | sed 's/\b nvidia_drm.modeset=.\b//g')
            sudo sed -i "/^options/c${sdopt} quiet splash nvidia_drm.modeset=1" ${imgconf}
        done
    else
        echo -e "\033[0;33m[SKIP]\033[0m systemd-boot is already configured..."
    fi
fi

# pacman
if [ -f /etc/pacman.conf ] && [ ! -f /etc/pacman.conf.t2.bkp ]; then
    echo -e "\033[0;32m[PACMAN]\033[0m adding extra spice to pacman..."

    sudo cp /etc/pacman.conf /etc/pacman.conf.t2.bkp
    sudo sed -i "/^#Color/c\Color\nILoveCandy
    /^#VerbosePkgLists/c\VerbosePkgLists
    /^#ParallelDownloads/c\ParallelDownloads = 5" /etc/pacman.conf
    sudo sed -i '/^#\[multilib\]/,+1 s/^#//' /etc/pacman.conf

    sudo pacman -Syyu
    sudo pacman -Fy

else
    echo -e "\033[0;33m[SKIP]\033[0m pacman is already configured..."
fi
