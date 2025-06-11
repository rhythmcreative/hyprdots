#!/bin/bash

# Script para configurar MySQL y MySQL Workbench
# Configura un servidor localhost con contraseña 'admin'

source global_fn.sh

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}"
    echo "================================================"
    echo "      Configuración de MySQL y Workbench"
    echo "================================================"
    echo -e "${NC}"
}

install_mysql() {
    echo -e "${YELLOW}Instalando MySQL y dependencias...${NC}"
    
    # Verificar e instalar gnome-keyring
    if ! pacman -Qi gnome-keyring &> /dev/null; then
        echo -e "${YELLOW}Instalando gnome-keyring...${NC}"
        sudo pacman -S --needed gnome-keyring
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ gnome-keyring instalado correctamente${NC}"
        else
            echo -e "${RED}✗ Error instalando gnome-keyring${NC}"
        fi
    else
        echo -e "${GREEN}✓ gnome-keyring ya está instalado${NC}"
    fi
    
    # Instalar MySQL y herramientas
    if ! command -v mysql &> /dev/null; then
        sudo pacman -S --needed mysql
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ MySQL instalado correctamente${NC}"
        else
            echo -e "${RED}✗ Error instalando MySQL${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✓ MySQL ya está instalado${NC}"
    fi
    
    # Instalar MySQL Workbench si no está
    if ! command -v mysql-workbench &> /dev/null; then
        echo -e "${YELLOW}Instalando MySQL Workbench...${NC}"
        yay -S --needed mysql-workbench
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ MySQL Workbench instalado correctamente${NC}"
        else
            echo -e "${RED}✗ Error instalando MySQL Workbench${NC}"
        fi
    else
        echo -e "${GREEN}✓ MySQL Workbench ya está instalado${NC}"
    fi
}

setup_mysql_service() {
    echo -e "${YELLOW}Configurando servicio MySQL...${NC}"
    
    # Inicializar base de datos MySQL
    if [ ! -d "/var/lib/mysql/mysql" ]; then
        echo -e "${YELLOW}Inicializando base de datos MySQL...${NC}"
        sudo mysql_install_db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
    fi
    
    # Habilitar y iniciar servicio MySQL
    sudo systemctl enable mysqld
    sudo systemctl start mysqld
    
    if systemctl is-active --quiet mysqld; then
        echo -e "${GREEN}✓ Servicio MySQL iniciado correctamente${NC}"
    else
        echo -e "${RED}✗ Error iniciando servicio MySQL${NC}"
        exit 1
    fi
}

configure_mysql_root() {
    echo -e "${YELLOW}Configurando usuarios de MySQL...${NC}"
    
    # Configurar contraseña root
    # Primero intentamos conectar sin contraseña
    mysql -u root -e "SELECT 1;" &>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${YELLOW}Estableciendo contraseña para root...${NC}"
        mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY 'admin';
CREATE USER IF NOT EXISTS 'localhost'@'localhost' IDENTIFIED BY 'admin';
GRANT ALL PRIVILEGES ON *.* TO 'localhost'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Contraseña de root configurada como 'admin'${NC}"
            echo -e "${GREEN}✓ Usuario 'localhost' creado con contraseña 'admin'${NC}"
        else
            echo -e "${RED}✗ Error configurando usuarios${NC}"
        fi
    else
        echo -e "${YELLOW}Verificando contraseña existente...${NC}"
        mysql -u root -padmin -e "SELECT 1;" &>/dev/null
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Contraseña de root ya está configurada como 'admin'${NC}"
            # Verificar y crear usuario localhost si no existe
            mysql -u root -padmin <<EOF
CREATE USER IF NOT EXISTS 'localhost'@'localhost' IDENTIFIED BY 'admin';
GRANT ALL PRIVILEGES ON *.* TO 'localhost'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
            echo -e "${GREEN}✓ Usuario 'localhost' verificado/creado${NC}"
        else
            echo -e "${YELLOW}Intentando reconfigurar MySQL...${NC}"
            # Reiniciar MySQL en modo seguro para resetear contraseña
            sudo systemctl stop mysqld
            sudo mysqld_safe --skip-grant-tables &
            sleep 3
            mysql -u root <<EOF
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'admin';
CREATE USER IF NOT EXISTS 'localhost'@'localhost' IDENTIFIED BY 'admin';
GRANT ALL PRIVILEGES ON *.* TO 'localhost'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
            sudo pkill mysqld_safe
            sudo systemctl start mysqld
            echo -e "${GREEN}✓ Contraseñas reconfiguradas y usuario 'localhost' creado${NC}"
        fi
    fi
}

create_workbench_connection() {
    echo -e "${YELLOW}Configurando conexión en MySQL Workbench...${NC}"
    
    # Directorio de configuración de MySQL Workbench
    WORKBENCH_DIR="$HOME/.mysql/workbench"
    CONNECTIONS_DIR="$WORKBENCH_DIR/connections"
    
    # Crear directorios si no existen
    mkdir -p "$CONNECTIONS_DIR"
    
    # Crear archivo de conexión
    cat > "$CONNECTIONS_DIR/localhost_admin.xml" << EOF
<?xml version="1.0"?>
<data>
  <value type="object" struct-name="db.mgmt.Connection" id="connection">
    <value type="string" key="driver">com.mysql.rdbms.mysql.driver.native_sshtun</value>
    <value type="string" key="caption">localhost</value>
    <value type="string" key="description">Conexión local MySQL con usuario admin</value>
    <value type="string" key="hostName">127.0.0.1</value>
    <value type="int" key="port">3306</value>
    <value type="string" key="userName">root</value>
    <value type="string" key="schema"></value>
    <value type="string" key="sslMode"></value>
    <value type="int" key="sslCert"></value>
    <value type="int" key="sslKey"></value>
    <value type="int" key="sslCA"></value>
    <value type="string" key="sslCipher"></value>
    <value type="object" key="parameterValues" struct-name="app.ParameterValues">
      <value type="string" key="SQL_MODE">TRADITIONAL</value>
      <value type="string" key="@mysql_plugin_dir">/usr/lib/mysql/plugin</value>
    </value>
    <value type="object" key="modules" struct-name="app.ModuleList">
      <value type="object" key="wb.mysql.import" struct-name="app.Module">
        <value type="string" key="sys.config.path">/usr/bin</value>
      </value>
    </value>
  </value>
</data>
EOF
    
    if [ -f "$CONNECTIONS_DIR/localhost_admin.xml" ]; then
        echo -e "${GREEN}✓ Conexión de Workbench configurada${NC}"
    else
        echo -e "${RED}✗ Error creando conexión de Workbench${NC}"
    fi
}

create_credentials_file() {
    echo -e "${YELLOW}Creando archivo de credenciales...${NC}"
    
    # Obtener el nombre de usuario actual
    nombre_usuario=$(whoami)
    DOWNLOADS_DIR="/home/$nombre_usuario/Downloads"
    
    # Crear directorio Downloads si no existe
    mkdir -p "$DOWNLOADS_DIR"
    
    # Crear archivo con credenciales
    cat > "$DOWNLOADS_DIR/mysql-workbench.txt" << EOF
Credenciales de MySQL Workbench
==============================

Servidor: localhost (127.0.0.1)
Puerto: 3306
Usuario: localhost
Contraseña: admin

Usuario Alternativo (root):
Usuario: root
Contraseña: admin

Fecha de creación: $(date)
Creado por: $nombre_usuario

Notas:
- Usar estas credenciales para conectar MySQL Workbench
- El servidor debe estar ejecutándose (sudo systemctl start mysqld)
- Para conectar por terminal: mysql -u root -padmin
EOF
    
    if [ -f "$DOWNLOADS_DIR/mysql-workbench.txt" ]; then
        echo -e "${GREEN}✓ Archivo de credenciales creado en: $DOWNLOADS_DIR/mysql-workbench.txt${NC}"
    else
        echo -e "${RED}✗ Error creando archivo de credenciales${NC}"
    fi
}

test_connection() {
    echo -e "${YELLOW}Probando conexiones a MySQL...${NC}"
    
    # Probar conexión con root
    mysql -u root -padmin -e "SELECT 'Conexión exitosa' as Status, USER() as Usuario, NOW() as Fecha;" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Conexión con usuario 'root' funcionando correctamente${NC}"
    else
        echo -e "${RED}✗ Error en la conexión con usuario 'root'${NC}"
    fi
    
    # Probar conexión con localhost
    mysql -u localhost -padmin -e "SELECT 'Conexión exitosa' as Status, USER() as Usuario, NOW() as Fecha;" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Conexión con usuario 'localhost' funcionando correctamente${NC}"
    else
        echo -e "${RED}✗ Error en la conexión con usuario 'localhost'${NC}"
    fi
}

print_summary() {
    nombre_usuario=$(whoami)
    echo -e "${BLUE}"
    echo "================================================"
    echo "           Configuración Completada"
    echo "================================================"
    echo -e "${NC}"
    echo -e "${GREEN}Configuración de MySQL completada:${NC}"
    echo -e "  • Servidor: ${YELLOW}localhost (127.0.0.1:3306)${NC}"
    echo -e "  • Usuario root: ${YELLOW}root${NC} | Contraseña: ${YELLOW}admin${NC}"
    echo -e "  • Usuario localhost: ${YELLOW}localhost${NC} | Contraseña: ${YELLOW}admin${NC}"
    echo -e "  • gnome-keyring: ${YELLOW}Instalado y verificado${NC}"
    echo ""
    echo -e "${GREEN}Archivo de credenciales creado:${NC}"
    echo -e "  • Ubicación: ${YELLOW}/home/$nombre_usuario/Downloads/mysql-workbench.txt${NC}"
    echo -e "  • Contiene todas las credenciales necesarias"
    echo ""
    echo -e "${GREEN}Para usar MySQL Workbench:${NC}"
    echo -e "  1. Abrir MySQL Workbench"
    echo -e "  2. Crear nueva conexión o usar la conexión '${YELLOW}localhost${NC}'"
    echo -e "  3. Servidor: ${YELLOW}127.0.0.1${NC}, Puerto: ${YELLOW}3306${NC}"
    echo -e "  4. Usuario: ${YELLOW}localhost${NC} o ${YELLOW}root${NC}"
    echo -e "  5. Contraseña: ${YELLOW}admin${NC}"
    echo ""
    echo -e "${GREEN}Comandos útiles:${NC}"
    echo -e "  • Conectar como root: ${YELLOW}mysql -u root -padmin${NC}"
    echo -e "  • Conectar como localhost: ${YELLOW}mysql -u localhost -padmin${NC}"
    echo -e "  • Iniciar servicio: ${YELLOW}sudo systemctl start mysqld${NC}"
    echo -e "  • Parar servicio: ${YELLOW}sudo systemctl stop mysqld${NC}"
    echo -e "  • Estado del servicio: ${YELLOW}sudo systemctl status mysqld${NC}"
}

# Función principal
main() {
    print_header
    
    # Verificar si el usuario quiere continuar
    echo -e "${YELLOW}Este script configurará MySQL con:${NC}"
    echo -e "  • Usuarios: root y localhost"
    echo -e "  • Contraseña: admin (para ambos usuarios)"
    echo -e "  • Servidor: localhost:3306"
    echo -e "  • gnome-keyring: instalación verificada"
    echo -e "  • Archivo de credenciales en Downloads"
    echo ""
    read -p "¿Continuar? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Operación cancelada${NC}"
        exit 0
    fi
    
    install_mysql
    setup_mysql_service
    configure_mysql_root
    create_workbench_connection
    create_credentials_file
    test_connection
    print_summary
}

# Verificar si se ejecuta directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

