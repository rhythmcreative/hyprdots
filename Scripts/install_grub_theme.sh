#!/usr/bin/env bash
#|---/ /+--------------------------------+---/ /|#
#|--/ /-| GRUB Hyperfluent Theme Installer |--/ /-|#
#|-/ /--| with LUKS encryption support    |-/ /--|#
#|/ /---+--------------------------------+/ /---|#

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
scrDir=$(dirname "$(realpath "$0")")

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -eq 0 ]; then
        print_error "Do not run this script as root. It will ask for sudo when needed."
        exit 1
    fi
}

# Function to check if GRUB is installed
check_grub() {
    if ! command -v grub-mkconfig &> /dev/null; then
        print_error "GRUB is not installed. Please install GRUB first."
        exit 1
    fi
    print_status "GRUB installation detected"
}

# Function to detect LUKS encryption
detect_luks() {
    if lsblk -f | grep -q "crypto_LUKS"; then
        print_status "LUKS encryption detected"
        return 0
    else
        print_warning "No LUKS encryption detected"
        return 1
    fi
}

# Function to download hyperfluent-arch theme
download_theme() {
    local theme_url="https://github.com/rhythmcreative/hyperfluent-grub-theme/archive/refs/heads/main.tar.gz"
    local theme_dir="$HOME/.cache/grub-theme"
    
    print_status "Creating cache directory..."
    mkdir -p "$theme_dir"
    
    print_status "Downloading hyperfluent-arch GRUB theme..."
    
    # Try multiple sources for the theme
    if curl -L -f -o "$theme_dir/hyperfluent-arch.tar.gz" "$theme_url" 2>/dev/null; then
        print_success "Theme downloaded successfully"
    elif curl -L -f -o "$theme_dir/hyperfluent-arch.tar.gz" "https://github.com/saber-linux/hyperfluent-grub-theme/archive/refs/heads/main.tar.gz" 2>/dev/null; then
        print_success "Theme downloaded from alternative source"
    elif wget -O "$theme_dir/hyperfluent-arch.tar.gz" "https://github.com/prasanthrangan/hyprdots/raw/main/Source/arcs/Grub_themes/hyperfluent-arch.tar.gz" 2>/dev/null; then
        print_success "Theme downloaded from hyprdots repository"
    else
        print_error "Failed to download theme from all sources"
        print_status "You can manually place the hyperfluent-arch.tar.gz file in $theme_dir"
        read -p "Press Enter after placing the file manually, or Ctrl+C to exit..."
        
        if [ ! -f "$theme_dir/hyperfluent-arch.tar.gz" ]; then
            print_error "Theme file not found. Exiting."
            exit 1
        fi
    fi
    
    echo "$theme_dir/hyperfluent-arch.tar.gz"
}

# Function to extract and install theme
install_theme() {
    local theme_file="$1"
    local grub_themes_dir="/usr/share/grub/themes"
    local temp_dir="$HOME/.cache/grub-theme-extract"
    
    print_status "Extracting theme..."
    rm -rf "$temp_dir"
    mkdir -p "$temp_dir"
    
    if tar -xzf "$theme_file" -C "$temp_dir" --strip-components=1 2>/dev/null; then
        print_success "Theme extracted successfully"
    else
        print_error "Failed to extract theme"
        exit 1
    fi
    
    # Find the theme directory
    local theme_name="hyperfluent-arch"
    if [ -d "$temp_dir/$theme_name" ]; then
        local theme_source="$temp_dir/$theme_name"
    elif [ -d "$temp_dir" ] && [ -f "$temp_dir/theme.txt" ]; then
        local theme_source="$temp_dir"
    else
        # Look for any directory with theme.txt
        local theme_source=$(find "$temp_dir" -name "theme.txt" -type f | head -1 | xargs dirname)
        if [ -z "$theme_source" ]; then
            print_error "Could not find theme files in extracted archive"
            exit 1
        fi
    fi
    
    print_status "Installing theme to $grub_themes_dir/$theme_name..."
    sudo mkdir -p "$grub_themes_dir"
    sudo rm -rf "$grub_themes_dir/$theme_name"
    sudo cp -r "$theme_source" "$grub_themes_dir/$theme_name"
    
    print_success "Theme installed successfully"
    
    # Cleanup
    rm -rf "$temp_dir"
}

# Function to configure GRUB with LUKS support
configure_grub() {
    local theme_name="hyperfluent-arch"
    local grub_config="/etc/default/grub"
    local backup_config="/etc/default/grub.backup.$(date +%Y%m%d_%H%M%S)"
    
    print_status "Backing up current GRUB configuration..."
    sudo cp "$grub_config" "$backup_config"
    print_status "Backup created: $backup_config"
    
    print_status "Configuring GRUB with hyperfluent-arch theme..."
    
    # Remove existing theme configuration
    sudo sed -i '/^GRUB_THEME=/d' "$grub_config"
    
    # Add theme configuration
    echo "GRUB_THEME=/usr/share/grub/themes/$theme_name/theme.txt" | sudo tee -a "$grub_config" > /dev/null
    
    # Configure for better LUKS support
    if detect_luks; then
        print_status "Configuring GRUB for LUKS encryption..."
        
        # Ensure GRUB_ENABLE_CRYPTODISK is set
        if ! grep -q "^GRUB_ENABLE_CRYPTODISK=" "$grub_config"; then
            echo "GRUB_ENABLE_CRYPTODISK=y" | sudo tee -a "$grub_config" > /dev/null
        else
            sudo sed -i 's/^GRUB_ENABLE_CRYPTODISK=.*/GRUB_ENABLE_CRYPTODISK=y/' "$grub_config"
        fi
        
        # Set timeout for encrypted systems (give user time to see the theme)
        if ! grep -q "^GRUB_TIMEOUT=" "$grub_config"; then
            echo "GRUB_TIMEOUT=10" | sudo tee -a "$grub_config" > /dev/null
        else
            sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=10/' "$grub_config"
        fi
        
        # Disable quiet mode to see boot messages if desired
        if grep -q "^GRUB_CMDLINE_LINUX_DEFAULT=.*quiet" "$grub_config"; then
            print_status "Note: 'quiet' parameter found in GRUB_CMDLINE_LINUX_DEFAULT"
            print_status "You may want to remove it to see boot messages"
        fi
    fi
    
    # Set GRUB resolution for better theme display
    if ! grep -q "^GRUB_GFXMODE=" "$grub_config"; then
        echo "GRUB_GFXMODE=1920x1080,1366x768,1024x768,auto" | sudo tee -a "$grub_config" > /dev/null
    fi
    
    # Enable GRUB graphics terminal
    if ! grep -q "^GRUB_TERMINAL=" "$grub_config"; then
        echo "GRUB_TERMINAL=gfxterm" | sudo tee -a "$grub_config" > /dev/null
    fi
    
    print_success "GRUB configuration updated"
}

# Function to regenerate GRUB configuration
regenerate_grub() {
    print_status "Regenerating GRUB configuration..."
    
    if sudo grub-mkconfig -o /boot/grub/grub.cfg; then
        print_success "GRUB configuration regenerated successfully"
    else
        print_error "Failed to regenerate GRUB configuration"
        exit 1
    fi
}

# Function to show installation summary
show_summary() {
    echo
    echo -e "${GREEN}=== Installation Summary ===${NC}"
    echo -e "${GREEN}✓${NC} Hyperfluent-arch GRUB theme installed"
    echo -e "${GREEN}✓${NC} GRUB configuration updated"
    
    if detect_luks > /dev/null; then
        echo -e "${GREEN}✓${NC} LUKS encryption support configured"
    fi
    
    echo -e "${GREEN}✓${NC} GRUB configuration regenerated"
    echo
    print_status "Theme installation completed successfully!"
    print_status "Reboot to see the new GRUB theme."
    echo
}

# Function to uninstall theme
uninstall_theme() {
    local theme_name="hyperfluent-arch"
    local grub_config="/etc/default/grub"
    
    print_status "Uninstalling hyperfluent-arch GRUB theme..."
    
    # Remove theme directory
    if [ -d "/usr/share/grub/themes/$theme_name" ]; then
        sudo rm -rf "/usr/share/grub/themes/$theme_name"
        print_status "Theme files removed"
    fi
    
    # Remove theme configuration from GRUB
    sudo sed -i '/^GRUB_THEME=/d' "$grub_config"
    print_status "Theme configuration removed from GRUB"
    
    # Regenerate GRUB configuration
    regenerate_grub
    
    print_success "Theme uninstalled successfully"
}

# Main function
main() {
    echo -e "${BLUE}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║            GRUB Hyperfluent Theme Installer           ║
║              with LUKS encryption support             ║
╚═══════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    check_root
    check_grub
    
    case "${1:-install}" in
        "install")
            print_status "Starting GRUB theme installation..."
            theme_file=$(download_theme)
            install_theme "$theme_file"
            configure_grub
            regenerate_grub
            show_summary
            ;;
        "uninstall")
            uninstall_theme
            ;;
        "--help"|-h)
            echo "Usage: $0 [install|uninstall]"
            echo "  install    - Install hyperfluent-arch GRUB theme (default)"
            echo "  uninstall  - Remove hyperfluent-arch GRUB theme"
            echo "  --help, -h - Show this help message"
            ;;
        *)
            print_error "Invalid option: $1"
            echo "Use '$0 --help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"

