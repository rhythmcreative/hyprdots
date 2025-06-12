#!/usr/bin/env bash
# Sober Configuration Script
# Configure Sober with optimized settings

USER_NAME=$(whoami)
SOBER_CONFIG_DIR="/home/$USER_NAME/.var/app/org.vinegarhq.Sober/config/sober"
CONFIG_FILE="$SOBER_CONFIG_DIR/config.json"
BACKUP_FILE="$SOBER_CONFIG_DIR/config1.json"

# Function to configure Sober
configure_sober() {
    echo "[INFO] Configuring Sober with optimized settings..."
    
    # Check if Sober config directory exists
    if [ ! -d "$SOBER_CONFIG_DIR" ]; then
        echo "[ERROR] Sober config directory not found: $SOBER_CONFIG_DIR"
        echo "[INFO] Sober (Roblox) doesn't appear to be installed."
        echo ""
        echo "Choose an option:"
        echo "1) Install Roblox (Sober) via Flatpak"
        echo "2) Skip Sober configuration (you can configure it later)"
        echo ""
        read -p "Enter your choice (1 or 2): " choice
        
        case $choice in
            1)
                echo "[INFO] Installing Sober (Roblox) via Flatpak..."
                flatpak install -y flathub org.vinegarhq.Sober
                if [ $? -eq 0 ]; then
                    echo "[SUCCESS] Sober installed successfully!"
                    echo "[INFO] Please run Sober once to create the configuration directory, then run this script again."
                    echo "[INFO] You can launch Sober from your application menu or run: flatpak run org.vinegarhq.Sober"
                    return 0  # Installation successful, continue with install.sh
                else
                    echo "[ERROR] Failed to install Sober. Skipping configuration."
                    return 0  # Failed installation but continue with install.sh
                fi
                ;;
            2)
                echo "[INFO] Skipping Sober configuration. You can run this script later after installing Sober."
                return 0  # User chose to skip, continue with install.sh
                ;;
            *)
                echo "[ERROR] Invalid choice. Skipping Sober configuration."
                return 0  # Invalid choice but continue with install.sh
                ;;
        esac
    fi
    
    # Check if config.json exists
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "[WARNING] config.json not found. Creating new configuration..."
    else
        # Backup existing config.json as config1.json
        echo "[INFO] Backing up existing config.json to config1.json..."
        cp "$CONFIG_FILE" "$BACKUP_FILE"
        
        if [ $? -eq 0 ]; then
            echo "[SUCCESS] Backup created successfully!"
        else
            echo "[ERROR] Failed to create backup. Aborting..."
            return 1
        fi
    fi
    
    # Create the new optimized configuration
    echo "[INFO] Creating optimized Sober configuration..."
    cat > "$CONFIG_FILE" << 'EOF'
{
    "FFlagEnableBubbleChatFromChatService": false,
    "allow_gamepad_permission": false,
    "bring_back_oof": false,
    "discord_rpc_enabled": false,
    "enable_gamemode": true,
    "enable_hidpi": false,
    "fflags": {
        "DFFlagDebugRenderForceTechnologyVoxel": true,
        "DFIntTaskSchedulerTargetFps": "999",
        "FFlagDebugForceFutureIsBrightPhase2": false,
        "FFlagDebugForceFutureIsBrightPhase3": false,
        "FFlagExample": true,
        "FFlagGameBasicSettingsFramerateCap5": false,
        "FFlagTaskSchedulerLimitTargetFpsTo2402": false
    },
    "server_location_indicator_enabled": false,
    "touch_mode": "off",
    "use_libsecret": false,
    "use_opengl": false
}
EOF
    
    if [ $? -eq 0 ]; then
        echo "[SUCCESS] Sober configuration updated successfully!"
    else
        echo "[ERROR] Failed to create configuration file"
        return 1
    fi
}

# Main script execution
echo "Sober Configuration Script"
configure_sober

