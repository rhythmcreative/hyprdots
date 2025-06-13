#!/usr/bin/env bash

#      ░▒▒▒░░░░░▓▓          ___________
#    ░░▒▒▒░░░░░▓▓        //___________/
#   ░░▒▒▒░░░░░▓▓     _   _ _    _ _____
#   ░░▒▒░░░░░▓▓▓▓▓▓ | | | | |  | |  __/
#    ░▒▒░░░░▓▓   ▓▓ | |_| | |_/ /| |___
#     ░▒▒░░▓▓   ▓▓   \__  |____/ |____/
#       ░▒▓▓   ▓▓  //____/

# HyDE nwg-dock-hyprland launcher script

# Source global functions
source "${HOME}/.local/share/bin/global_fn.sh"

# Configuration paths
CONFIG_DIR="${HOME}/.config/nwg-dock-hyprland"
CONFIG_FILE="${CONFIG_DIR}/config.jsonc"
STYLE_FILE="${CONFIG_DIR}/style.css"
HYDE_CONF="${HOME}/.config/hyde/hyde.conf"

# Function to check if nwg-dock is running
check_dock_running() {
    pgrep -x "nwg-dock-hyprland" > /dev/null 2>&1
}

# Function to kill existing dock instance
kill_dock() {
    if check_dock_running; then
        echo "Stopping existing nwg-dock-hyprland instance..."
        pkill -x "nwg-dock-hyprland"
        sleep 1
    fi
}

# Function to start the dock
start_dock() {
    echo "Starting nwg-dock-hyprland with HyDE integration..."
    
    # Check if config files exist
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Error: Configuration file not found at $CONFIG_FILE"
        exit 1
    fi
    
    if [[ ! -f "$STYLE_FILE" ]]; then
        echo "Warning: Style file not found at $STYLE_FILE"
    fi
    
    # Launch nwg-dock with configuration
    nwg-dock-hyprland -c "$CONFIG_FILE" -s "$STYLE_FILE" &
    
    echo "nwg-dock-hyprland started successfully!"
}

# Function to restart the dock
restart_dock() {
    echo "Restarting nwg-dock-hyprland..."
    kill_dock
    sleep 2
    start_dock
}

# Function to toggle dock visibility
toggle_dock() {
    if check_dock_running; then
        echo "Hiding nwg-dock-hyprland..."
        kill_dock
    else
        echo "Showing nwg-dock-hyprland..."
        start_dock
    fi
}

# Function to check status
status_dock() {
    if check_dock_running; then
        echo "nwg-dock-hyprland is running"
        return 0
    else
        echo "nwg-dock-hyprland is not running"
        return 1
    fi
}

# Function to show help
show_help() {
    echo "HyDE nwg-dock-hyprland launcher"
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  start     Start nwg-dock-hyprland"
    echo "  stop      Stop nwg-dock-hyprland"
    echo "  restart   Restart nwg-dock-hyprland"
    echo "  toggle    Toggle dock visibility"
    echo "  status    Check if dock is running"
    echo "  help      Show this help message"
    echo ""
    echo "If no option is provided, 'start' is assumed."
}

# Main script logic
case "${1:-start}" in
    "start")
        if check_dock_running; then
            echo "nwg-dock-hyprland is already running"
        else
            start_dock
        fi
        ;;
    "stop")
        kill_dock
        ;;
    "restart")
        restart_dock
        ;;
    "toggle")
        toggle_dock
        ;;
    "status")
        status_dock
        ;;
    "help" | "-h" | "--help")
        show_help
        ;;
    *)
        echo "Unknown option: $1"
        echo "Use '$0 help' for usage information."
        exit 1
        ;;
esac

