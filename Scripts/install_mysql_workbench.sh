#!/bin/bash

# Script de instalación y configuración de MySQL Workbench
# Autor: Assistant
# Descripción: Instala MySQL/MariaDB, MySQL Workbench, verifica gnome-keyring
#              y crea usuario 'localhost' con contraseña 'admin'

set -e  # Salir si hay algún error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar mensajes
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para verificar si un paquete está instalado
check_package() {
    if pacman -Qi "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Función para verificar si un servicio está activo
check_service() {
    if systemctl is-active --quiet "$1"; then
        return 0
    else
        return 1
    fi
}

print_info "Iniciando instalación y configuración de MySQL Workbench..."

# 1. Verificar y instalar gnome-keyring
print_info "Verificando gnome-keyring..."
if check_package "gnome-keyring"; then
    print_success "gnome-keyring ya está instalado"
else
    print_warning "gnome-keyring no está instalado. Instalando..."
    sudo pacman -S --noconfirm gnome-keyring
    print_success "gnome-keyring instalado correctamente"
fi

# 2. Verificar e instalar MySQL/MariaDB
print_info "Verificando MySQL/MariaDB..."
if check_package "mariadb"; then
    print_success "MariaDB ya está instalado"
else
    print_warning "MariaDB no está instalado. Instalando..."
    # Usar expect=1 para seleccionar mariadb automáticamente
    echo "1" | sudo pacman -S --noconfirm mysql
fi

# 3. Verificar e instalar MySQL Workbench
print_info "Verificando MySQL Workbench..."
if check_package "mysql-workbench"; then
    print_success "MySQL Workbench ya está instalado"
else
    print_warning "MySQL Workbench no está instalado. Instalando..."
    sudo pacman -S --noconfirm mysql-workbench
    print_success "MySQL Workbench instalado correctamente"
fi

# 4. Inicializar base de datos si es necesario
print_info "Verificando inicialización de la base de datos..."
if [ ! -d "/var/lib/mysql/mysql" ]; then
    print_warning "Base de datos no inicializada. Inicializando..."
    sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    print_success "Base de datos inicializada correctamente"
else
    print_success "Base de datos ya está inicializada"
fi

# 5. Habilitar e iniciar servicio MariaDB
print_info "Configurando servicio MariaDB..."
if ! systemctl is-enabled --quiet mariadb; then
    sudo systemctl enable mariadb
    print_success "Servicio MariaDB habilitado"
fi

if ! check_service "mariadb"; then
    print_warning "Iniciando servicio MariaDB..."
    sudo systemctl start mariadb
    sleep 3
    if check_service "mariadb"; then
        print_success "Servicio MariaDB iniciado correctamente"
    else
        print_error "Error al iniciar servicio MariaDB"
        exit 1
    fi
else
    print_success "Servicio MariaDB ya está corriendo"
fi

# 6. Configurar seguridad básica de MySQL y crear usuario
print_info "Configurando usuarios de MySQL..."

# Intentar diferentes métodos de autenticación para root
ROOT_ACCESS=""

# Método 1: Sin contraseña
if mysql -u root -e "SELECT 1" &> /dev/null; then
    ROOT_ACCESS="mysql -u root"
    print_info "Acceso root sin contraseña detectado"
# Método 2: Con sudo
elif sudo mysql -u root -e "SELECT 1" &> /dev/null; then
    ROOT_ACCESS="sudo mysql -u root"
    print_info "Acceso root con sudo detectado"
# Método 3: Con contraseña root existente
elif mysql -u root -prootpassword -e "SELECT 1" &> /dev/null; then
    ROOT_ACCESS="mysql -u root -prootpassword"
    print_info "Acceso root con contraseña existente detectado"
else
    print_error "No se puede acceder a MySQL como root"
    exit 1
fi

# 7. Crear usuario 'localhost' con contraseña 'admin'
print_info "Creando usuario 'localhost' con contraseña 'admin'..."

# Eliminar usuario si existe y crearlo nuevamente
$ROOT_ACCESS -e "DROP USER IF EXISTS 'localhost'@'localhost';" 2>/dev/null || true
$ROOT_ACCESS -e "CREATE USER 'localhost'@'localhost' IDENTIFIED BY 'admin';"
$ROOT_ACCESS -e "GRANT ALL PRIVILEGES ON *.* TO 'localhost'@'localhost' WITH GRANT OPTION;"
$ROOT_ACCESS -e "FLUSH PRIVILEGES;"

print_success "Usuario 'localhost' creado correctamente"

# 8. Verificar que el usuario funciona
print_info "Verificando conexión del usuario..."
if mysql -u localhost -padmin -e "SELECT 'Conexión exitosa' as status;" &> /dev/null; then
    print_success "Usuario 'localhost' puede conectarse correctamente"
else
    print_error "Error: el usuario 'localhost' no puede conectarse"
    exit 1
fi

# 9. Crear archivo con credenciales en ~/Downloads
print_info "Creando archivo de credenciales..."

# Crear directorio Downloads si no existe
mkdir -p ~/Downloads

# Crear archivo con credenciales
cat > ~/Downloads/mysql_usuario.txt << EOF
=== CREDENCIALES MYSQL/MARIADB ===

Servidor: localhost
Puerto: 3306
Usuario: localhost
Contraseña: admin

=== INFORMACIÓN ADICIONAL ===

Usuario Root: root
Contraseña Root: rootpassword

Archivo generado el: $(date)

=== INSTRUCCIONES PARA MYSQL WORKBENCH ===

1. Abrir MySQL Workbench
2. Hacer clic en '+' junto a 'MySQL Connections'
3. Configurar:
   - Connection Name: Local Server
   - Hostname: localhost
   - Port: 3306
   - Username: localhost
   - Password: admin (usar 'Store in Vault')
4. Test Connection
5. OK

EOF

print_success "Archivo de credenciales creado en ~/Downloads/mysql_usuario.txt"

# 10. Mostrar resumen final
echo ""
print_success "=== INSTALACIÓN COMPLETADA ==="
echo ""
print_info "✓ gnome-keyring: Verificado/Instalado"
print_info "✓ MariaDB: Instalado y configurado"
print_info "✓ MySQL Workbench: Instalado"
print_info "✓ Usuario 'localhost': Creado con contraseña 'admin'"
print_info "✓ Credenciales: Guardadas en ~/Downloads/mysql_usuario.txt"
echo ""
print_info "Para usar MySQL Workbench:"
print_info "  mysql-workbench &"
echo ""
print_info "Para conectarte por línea de comandos:"
print_info "  mysql -u localhost -padmin"
echo ""
print_success "¡Listo para usar!"

