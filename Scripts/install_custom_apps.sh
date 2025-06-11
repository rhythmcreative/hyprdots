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
            echo "[SUCCESS] SDDM Astronaut theme installed successfully!"
        else
            echo "[ERROR] Failed to copy theme files"
        fi
        
        # Clean up
        rm -rf sddm-astronaut-theme
    else
        echo "[ERROR] Failed to clone SDDM Astronaut theme repository"
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
        ;;
    *)
        echo "[INFO] Installation cancelled by user."
        exit 0
        ;;
esac

echo "[DONE] Custom applications installation script completed!"

