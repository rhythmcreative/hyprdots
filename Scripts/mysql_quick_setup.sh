#!/bin/bash

# Script rápido para configurar MySQL con contraseña admin
# Para uso en otros scripts de instalación

source "$(dirname "$0")/global_fn.sh" 2>/dev/null || true

setup_mysql_quick() {
    echo "Configurando MySQL con contraseña admin..."
    
    # Instalar MySQL si no está instalado
    if ! command -v mysql &> /dev/null; then
        echo "Instalando MySQL..."
        sudo pacman -S --needed mysql --noconfirm
    fi
    
    # Inicializar base de datos si es necesario
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        sudo mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    fi
    
    # Iniciar servicio
    sudo systemctl enable mysqld --now
    
    # Esperar a que MySQL esté listo
    sleep 3
    
    # Configurar contraseña
    mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'admin'; FLUSH PRIVILEGES;" 2>/dev/null || {
        # Si falla, intentar sin contraseña existente
        echo "Configurando contraseña inicial..."
        mysql -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY 'admin';
FLUSH PRIVILEGES;
EOF
    }
    
    echo "✓ MySQL configurado con contraseña 'admin'"
}

# Si se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_mysql_quick
fi

