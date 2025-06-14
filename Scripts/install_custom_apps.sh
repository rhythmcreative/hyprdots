#!/usr/bin/env bash
#|---/ /+--------------------------------------------------+---/ /|#
#|--/ /-| Custom Applications Installer                    |--/ /-|#
#|-/ /--| Install custom applications                       |-/ /--|#
#|/ /---+--------------------------------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
source "${scrDir}/global_fn.sh"
if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

# Define applications to install
declare -a AUR_APPS=(
    "balena-etcher"              # Flash OS images to SD cards & USB drives
    "localsend"                 # Cross-platform file sharing
    "nwg-displays"              # Output management utility for Wayland
    "discord"                   # Voice and text chat for gamers
    "steam"                     # Gaming platform
    "twitter"                   # Twitter client
    "chromium"                  # Open-source web browser
    "telegram-desktop"          # Telegram messaging app
    "crunchyroll"               # Anime streaming service
    "curseforge"                # Minecraft mod manager
    "virtualbox"                # Virtualization software
    "komikku"                   # Manga reader
    "libreoffice-fresh"         # Office suite
    "mysql-workbench"           # MySQL database tool
    "obsidian"                  # Note-taking app
    "wootility"                 # Wooting keyboard utility
    "zulucrypt"                 # Encryption utility
    "ani-cli"                   # Anime streaming CLI
    "minecraft-launcher"        # Official Minecraft launcher
    "warp-terminal"             # Modern terminal with AI features
    "tela-circle-icon-theme"    # Modern circular icon theme
    "dolphin"                   # KDE file manager
    "ark"                       # KDE file archiver
)

# Define Flatpak applications to install
declare -a FLATPAK_APPS=(
    "io.missioncenter.MissionCenter"  # System monitor application
)

# Warp terminal installation function
install_warp() {
    echo "[INFO] Installing Warp Terminal..."
    
    # Check if yay is available
    if ! command -v yay &> /dev/null; then
        echo "[ERROR] yay AUR helper is not installed!"
        echo "[INFO] Please install yay first using: bash install_aur.sh"
        return 1
    fi
    
    # Try to install from AUR first
    echo "[INFO] Attempting to install Warp Terminal from AUR..."
    yay -S warp-terminal --noconfirm --needed
    
    if [ $? -eq 0 ]; then
        echo "[SUCCESS] Warp Terminal installed successfully from AUR!"
        return 0
    fi
    
    # If AUR fails, try direct download method
    echo "[INFO] AUR installation failed, trying direct download..."
    cd /tmp
    
    # Get the actual download URL by following redirects
    echo "[DOWNLOAD] Getting Warp Terminal download URL..."
    download_url=$(curl -Ls -o /dev/null -w %{url_effective} "https://app.warp.dev/get_warp?package=pacman")
    
    if [[ "$download_url" == *.pkg.tar.* ]]; then
        echo "[DOWNLOAD] Downloading Warp Terminal package from: $download_url"
        wget -O warp-terminal.pkg.tar.xz "$download_url"
        
        if [ $? -eq 0 ] && [ -f warp-terminal.pkg.tar.xz ]; then
            # Verify it's actually a package file
            file_type=$(file warp-terminal.pkg.tar.xz)
            if [[ "$file_type" == *"compressed"* ]] || [[ "$file_type" == *"archive"* ]]; then
                echo "[SUCCESS] Package downloaded successfully"
                echo "[INFO] Installing Warp with pacman..."
                sudo pacman -U warp-terminal.pkg.tar.xz --noconfirm
                
                if [ $? -eq 0 ]; then
                    echo "[SUCCESS] Warp Terminal installed successfully!"
                else
                    echo "[ERROR] Failed to install Warp Terminal package"
                fi
            else
                echo "[ERROR] Downloaded file is not a valid package archive"
                echo "[INFO] File type: $file_type"
            fi
            
            # Clean up
            rm -f warp-terminal.pkg.tar.xz
        else
            echo "[ERROR] Failed to download Warp Terminal package"
        fi
    else
        echo "[ERROR] Could not get valid download URL for Warp Terminal"
        echo "[INFO] You may need to install Warp Terminal manually from https://app.warp.dev/"
    fi
}

# SDDM Astronaut theme installation function
install_sddm_astronaut() {
    echo "[INFO] Installing SDDM Astronaut Theme..."
    
    # Clone the repository
    cd /tmp
    echo "[DOWNLOAD] Cloning SDDM Astronaut theme repository..."
    git clone https://github.com/rhythmcreative/sddm-astronaut-theme.git
    
    if [ $? -eq 0 ]; then
        echo "[SUCCESS] Repository cloned successfully"
        
        # Create themes directory if it doesn't exist
        sudo mkdir -p /usr/share/sddm/themes/
        
        # Copy theme to system directory
        echo "[INFO] Installing theme to /usr/share/sddm/themes/..."
        sudo cp -r sddm-astronaut-theme/sddm-astronaut-theme /usr/share/sddm/themes/
        
        if [ $? -eq 0 ]; then
            # Create kde_settings.conf for the theme
            echo "[INFO] Creating configuration file..."
            sudo tee /usr/share/sddm/themes/sddm-astronaut-theme/kde_settings.conf > /dev/null << EOF
[Autologin]
Relogin=false
Session=
User=

[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[Theme]
Current=sddm-astronaut-theme

[Users]
MaximumUid=60513
MinimumUid=1000
EOF
            
            # Configure SDDM to use the astronaut theme as default
            echo "[INFO] Configuring SDDM to use astronaut theme as default..."
            sudo mkdir -p /etc/sddm.conf.d
            sudo tee /etc/sddm.conf.d/theme.conf > /dev/null << EOF
[Theme]
Current=sddm-astronaut-theme
EOF
            
            # Also update main sddm.conf if it exists
            if [ -f /etc/sddm.conf ]; then
                echo "[INFO] Updating existing /etc/sddm.conf..."
                sudo sed -i '/^Current=/d' /etc/sddm.conf
                sudo sed -i '/^\[Theme\]/a Current=sddm-astronaut-theme' /etc/sddm.conf
            else
                echo "[INFO] Creating /etc/sddm.conf..."
                sudo tee /etc/sddm.conf > /dev/null << EOF
[Theme]
Current=sddm-astronaut-theme
EOF
            fi
            
            echo "[SUCCESS] SDDM Astronaut theme installed and configured as default!"
        else
            echo "[ERROR] Failed to copy theme files"
        fi
        
        # Clean up
        rm -rf sddm-astronaut-theme
    else
        echo "[ERROR] Failed to clone SDDM Astronaut theme repository"
    fi
}

# BG-SDDM installation function
install_bg_sddm() {
    echo "[INFO] Installing BG-SDDM (SDDM Background Manager with GIFs support)..."
    
    # Clone the repository
    cd /tmp
    echo "[DOWNLOAD] Cloning BG-SDDM repository..."
    git clone https://github.com/rhythmcreative/BG-SDDM.git
    
    if [ $? -eq 0 ]; then
        echo "[SUCCESS] Repository cloned successfully"
        
        # Navigate to the repository directory
        cd BG-SDDM
        
        # Make the install script executable and run it
        echo "[INFO] Making install script executable..."
        chmod +x install.sh
        
        echo "[INFO] Running installation script..."
        ./install.sh
        
        if [ $? -eq 0 ]; then
            echo "[SUCCESS] BG-SDDM installed successfully!"
        else
            echo "[ERROR] Failed to install BG-SDDM"
        fi
        
        # Clean up
        cd /tmp
        rm -rf BG-SDDM
    else
        echo "[ERROR] Failed to clone BG-SDDM repository"
    fi
}

# Function to install Flatpak applications
install_flatpak_apps() {
    echo "[INFO] Installing Flatpak applications..."
    
    # Check if flatpak is installed
    if ! command -v flatpak &> /dev/null; then
        echo "[ERROR] Flatpak is not installed!"
        echo "[INFO] Installing Flatpak..."
        sudo pacman -S flatpak --noconfirm --needed
        
        if [ $? -ne 0 ]; then
            echo "[ERROR] Failed to install Flatpak"
            return 1
        fi
    fi
    
    # Add Flathub repository if not already added
    echo "[INFO] Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    # Install Flatpak applications
    for app in "${FLATPAK_APPS[@]}"; do
        echo "[INSTALLING] $app (Flatpak)"
        flatpak install flathub "$app" -y
        
        if [ $? -eq 0 ]; then
            echo "[SUCCESS] $app installed successfully!"
        else
            echo "[ERROR] Failed to install $app"
        fi
        echo ""
    done
}

# Configure dolphin as default file manager
configure_dolphin() {
    echo "[INFO] Configuring Dolphin as default file manager..."
    
    # Check if dolphin and xdg-utils are installed
    if command -v dolphin >/dev/null 2>&1 && command -v xdg-mime >/dev/null 2>&1; then
        echo "[INFO] Setting Dolphin as default file manager..."
        xdg-mime default org.kde.dolphin.desktop inode/directory
        
        # Verify the setting
        current_default=$(xdg-mime query default "inode/directory")
        echo "[INFO] Current default file manager: $current_default"
        
        if [[ "$current_default" == "org.kde.dolphin.desktop" ]]; then
            echo "[SUCCESS] Dolphin configured as default file manager!"
        else
            echo "[WARNING] Failed to set Dolphin as default file manager"
        fi
    else
        echo "[WARNING] Dolphin or xdg-utils not found, skipping configuration"
    fi
}

# Function to display applications list
show_apps_list() {
    echo "==========================================="
    echo "        APPLICATIONS TO INSTALL"
    echo "==========================================="
    
    local counter=1
    for app in "${AUR_APPS[@]}"; do
        printf "%2d. %s\n" $counter "$app"
        ((counter++))
    done
    
    printf "%2d. %s\n" $counter "sddm-astronaut-theme (from GitHub)"
    echo "==========================================="
}

# Main installation function
install_applications() {
    echo "[INFO] Starting installation of custom applications..."
    echo ""
    
    # Check if yay is installed
    if ! command -v yay &> /dev/null; then
        echo "[ERROR] yay AUR helper is not installed!"
        echo "[INFO] Please install yay first using: bash install_aur.sh"
        exit 1
    fi
    
    # Install AUR applications
    echo "[INFO] Installing AUR applications..."
    for app in "${AUR_APPS[@]}"; do
        echo "[INSTALLING] $app"
        yay -S "$app" --noconfirm --needed
        
        if [ $? -eq 0 ]; then
            echo "[SUCCESS] $app installed successfully!"
        else
            echo "[ERROR] Failed to install $app"
        fi
        echo ""
    done
    
    # Note: Warp Terminal is now installed via AUR in the main loop above
    
    # Install SDDM Astronaut Theme
    install_sddm_astronaut
    
    # Install BG-SDDM
    install_bg_sddm
    
    # Install Flatpak applications
    install_flatpak_apps
    
    # Configure Dolphin as default file manager
    configure_dolphin
    
    echo ""
    echo "==========================================="
    echo "       INSTALLATION COMPLETE!"
    echo "     All applications installed"
    echo "==========================================="
}

# Main script execution
echo "Custom Applications Installer"
echo ""
show_apps_list
echo ""

echo "Do you want to install these apps? (y/N): "
read -r response

case $response in
    [yY][eE][sS]|[yY])
        install_applications
        
        # Configure MySQL if it was installed
        if command -v mysql &> /dev/null && [[ " ${selected_apps[*]} " =~ " mysql " ]]; then
            echo "[INFO] MySQL detected, configuring with admin password..."
            if [[ -f "$(dirname "$0")/mysql_quick_setup.sh" ]]; then
                source "$(dirname "$0")/mysql_quick_setup.sh"
                setup_mysql_quick
                echo "[INFO] MySQL configured with username: root, password: admin"
            else
                echo "[WARNING] MySQL setup script not found. Run './setup_mysql.sh' manually."
            fi
        fi
        ;;
    *)
        echo "[INFO] Installation cancelled by user."
        exit 0
        ;;
esac

echo "[DONE] Custom applications installation script completed!"
echo "[INFO] If you installed MySQL, it's configured with:"
echo "       - Server: localhost:3306"
echo "       - Username: root"
echo "       - Password: admin"

