#!/bin/bash

# Script to fix hyprland.conf globbing error on line 142
# This script handles the missing nvidia.conf file that causes the "globbing error found no match"

CONF_FILE="/home/rhythmcreative/.config/hypr/hyprland.conf"
NVIDIA_CONF="/home/rhythmcreative/.config/hypr/nvidia.conf"
BACKUP_FILE="${CONF_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

echo "Fixing hyprland.conf globbing error..."

# Create backup of original config
echo "Creating backup: $BACKUP_FILE"
cp "$CONF_FILE" "$BACKUP_FILE"

# Check if nvidia.conf exists
if [ ! -f "$NVIDIA_CONF" ]; then
    echo "nvidia.conf not found. Choose fix method:"
    echo "1) Create empty nvidia.conf file (recommended)"
    echo "2) Comment out the problematic source line"
    echo "3) Create nvidia.conf with common NVIDIA settings"
    read -p "Enter choice (1/2/3): " choice
    
    case $choice in
        1)
            echo "Creating empty nvidia.conf file..."
            touch "$NVIDIA_CONF"
            echo "# NVIDIA-specific Hyprland configuration" > "$NVIDIA_CONF"
            echo "# Add your NVIDIA settings here if needed" >> "$NVIDIA_CONF"
            echo "Empty nvidia.conf created successfully!"
            ;;
        2)
            echo "Commenting out the problematic source line..."
            sed -i '142s/^source = /#source = /' "$CONF_FILE"
            echo "Line 142 commented out successfully!"
            ;;
        3)
            echo "Creating nvidia.conf with common NVIDIA settings..."
            cat > "$NVIDIA_CONF" << 'EOF'
# NVIDIA-specific Hyprland configuration
# These settings help with NVIDIA GPU compatibility

# Environment variables for NVIDIA
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia

# Cursor environment variable
env = WLR_NO_HARDWARE_CURSORS,1

# NVIDIA-specific rendering settings
render {
    explicit_sync = 2
}
EOF
            echo "nvidia.conf created with common NVIDIA settings!"
            ;;
        *)
            echo "Invalid choice. Creating empty nvidia.conf as default..."
            touch "$NVIDIA_CONF"
            echo "# NVIDIA-specific Hyprland configuration" > "$NVIDIA_CONF"
            echo "# Add your NVIDIA settings here if needed" >> "$NVIDIA_CONF"
            ;;
    esac
else
    echo "nvidia.conf already exists. No changes needed."
fi

echo ""
echo "Fix completed! Backup saved as: $BACKUP_FILE"
echo "Reloading Hyprland configuration..."
echo ""

# Reload Hyprland configuration
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload
    echo "Hyprland configuration reloaded successfully!"
else
    echo "hyprctl not found. Please reload manually with: hyprctl reload"
fi

echo ""
echo "If you need to restore the backup:"
echo "cp '$BACKUP_FILE' '$CONF_FILE'"

