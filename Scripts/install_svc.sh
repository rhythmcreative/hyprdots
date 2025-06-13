#!/usr/bin/env bash
#|---/ /+--------------------------+---/ /|#
#|--/ /-| Service enabler script   |--/ /-|#
#|--/ /-| Prasanth Rangan          |--/ /-|#
#|/ /---+--------------------------+/ /---|#

#--------------------------------#
# import variables and functions #
#--------------------------------#
scrDir=$(dirname "$(realpath "$0")")
source "${scrDir}/global_fn.sh"
if [ $? -ne 0 ]; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

#-----------------#
# enable services #
#-----------------#
service_ctl() {
    local svc="$1"
    local ctl="$2"
    
    if systemctl list-unit-files "${svc}.service" | grep -q "${svc}.service"; then
        echo -e "\033[0;33m[SERVICE]\033[0m ${ctl}ing ${svc} service..."
        sudo systemctl "${ctl}" "${svc}.service"
        
        if [ $? -eq 0 ]; then
            echo -e "\033[0;32m[SUCCESS]\033[0m ${svc} service ${ctl}ed successfully"
        else
            echo -e "\033[0;31m[ERROR]\033[0m Failed to ${ctl} ${svc} service"
        fi
    else
        echo -e "\033[0;33m[SKIP]\033[0m ${svc} service not found, skipping..."
    fi
}

echo -e "\033[0;32m[SERVICES]\033[0m Enabling system services..."
echo ""

# Read services from system_ctl.lst and enable them
if [ -f "${scrDir}/system_ctl.lst" ]; then
    while IFS= read -r service; do
        # Skip empty lines and comments
        [[ -z "$service" || "$service" =~ ^[[:space:]]*# ]] && continue
        
        # Remove any trailing whitespace/newlines
        service=$(echo "$service" | tr -d '\r\n' | xargs)
        
        if [ ! -z "$service" ]; then
            service_ctl "$service" "enable"
        fi
    done < "${scrDir}/system_ctl.lst"
else
    echo -e "\033[0;33m[WARNING]\033[0m system_ctl.lst not found, enabling default services..."
    
    # Default services to enable
    default_services=("NetworkManager" "bluetooth")
    
    for service in "${default_services[@]}"; do
        service_ctl "$service" "enable"
    done
fi

echo ""
echo -e "\033[0;32m[COMPLETE]\033[0m System services configuration completed!"
echo -e "\033[0;33m[INFO]\033[0m Some services may require a reboot to take effect"

