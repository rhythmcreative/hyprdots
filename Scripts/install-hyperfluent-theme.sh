#!/bin/bash

# Script de instalación del tema hyperfluent-arch para GRUB
# Funciona tanto con LUKS como sin LUKS
# Autor: Instalador automático
# Fecha: $(date +"%Y-%m-%d")

set -e  # Salir si hay algún error

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para imprimir mensajes coloreados
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

# Función para verificar si el usuario es root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Este script no debe ejecutarse como root. Usa sudo cuando sea necesario."
        exit 1
    fi
}

# Función para verificar dependencias
check_dependencies() {
    print_info "Verificando dependencias..."
    
    local deps=("unzip" "grub-mkconfig")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_error "Dependencias faltantes: ${missing_deps[*]}"
        print_info "En Arch Linux, instala con: sudo pacman -S ${missing_deps[*]}"
        exit 1
    fi
    
    print_success "Todas las dependencias están instaladas"
}

# Función para detectar si el sistema usa LUKS
detect_luks() {
    print_info "Detectando configuración de cifrado..."
    
    if lsblk -f | grep -q "crypto_LUKS" || 
       grep -q "cryptdevice=" /proc/cmdline 2>/dev/null ||
       [ -f /etc/crypttab ] && [ -s /etc/crypttab ]; then
        print_info "Sistema con LUKS detectado"
        return 0
    else
        print_info "Sistema sin LUKS detectado"
        return 1
    fi
}

# Función para verificar la ubicación de GRUB
detect_grub_location() {
    if [ -d "/boot/grub" ]; then
        GRUB_DIR="/boot/grub"
    elif [ -d "/boot/grub2" ]; then
        GRUB_DIR="/boot/grub2"
    else
        print_error "No se pudo encontrar el directorio de GRUB"
        exit 1
    fi
    
    print_info "Directorio de GRUB detectado: $GRUB_DIR"
}

# Función para verificar el archivo del tema
check_theme_file() {
    # Buscar el archivo en la ubicación específica de hyprdots
    local theme_file="/home/rhythmcreative/hyprdots/Source/arcs/hyperfluent-arch.tar.gz"
    
    if [ ! -f "$theme_file" ]; then
        print_error "Archivo del tema no encontrado en: $theme_file"
        print_info "Asegúrate de que el archivo hyperfluent-arch.tar.gz esté en /home/rhythmcreative/hyprdots/Source/arcs/"
        exit 1
    fi
    
    # Establecer la variable global para usar en otras funciones
    THEME_FILE="$theme_file"
    print_success "Archivo del tema encontrado: $theme_file"
}

# Función para extraer el tema
extract_theme() {
    print_info "Extrayendo el tema..."
    
    # Crear directorio temporal para la extracción
    local temp_dir="/tmp/hyperfluent-theme-extract"
    mkdir -p "$temp_dir"
    cd "$temp_dir"
    
    # Verificar el tipo de archivo
    local file_type=$(file "$THEME_FILE" | cut -d: -f2)
    
    if [[ $file_type == *"Zip"* ]]; then
        if [ -f "theme.txt" ]; then
            print_warning "Los archivos del tema ya están extraídos"
        else
            unzip -q "$THEME_FILE"
            print_success "Tema extraído usando unzip"
        fi
    elif [[ $file_type == *"gzip"* ]] || [[ $file_type == *"tar"* ]]; then
        if [ -f "theme.txt" ]; then
            print_warning "Los archivos del tema ya están extraídos"
        else
            tar -xzf "$THEME_FILE"
            print_success "Tema extraído usando tar"
        fi
    else
        print_error "Formato de archivo no reconocido"
        exit 1
    fi
    
    # Verificar que los archivos importantes estén presentes
    if [ ! -f "theme.txt" ] || [ ! -f "background.png" ] || [ ! -d "icons" ]; then
        print_error "Archivos del tema incompletos después de la extracción"
        exit 1
    fi
    
    # Establecer variable global del directorio de extracción
    EXTRACT_DIR="$temp_dir"
}

# Función para instalar el tema
install_theme() {
    print_info "Instalando el tema hyperfluent-arch..."
    
    local theme_dir="$GRUB_DIR/themes/hyperfluent-arch"
    
    # Crear directorio del tema
    print_info "Creando directorio del tema: $theme_dir"
    sudo mkdir -p "$theme_dir"
    
    # Cambiar al directorio de extracción
    cd "$EXTRACT_DIR"
    
    # Copiar archivos del tema
    print_info "Copiando archivos del tema..."
    sudo cp -r *.png *.pf2 theme.txt icons "$theme_dir/"
    
    # Verificar que los archivos se copiaron correctamente
    if [ ! -f "$theme_dir/theme.txt" ]; then
        print_error "Error al copiar los archivos del tema"
        exit 1
    fi
    
    print_success "Archivos del tema copiados correctamente"
}

# Función para configurar GRUB
configure_grub() {
    print_info "Configurando GRUB..."
    
    local grub_config="/etc/default/grub"
    local theme_path="$GRUB_DIR/themes/hyperfluent-arch/theme.txt"
    
    # Hacer backup del archivo de configuración
    print_info "Creando backup de la configuración de GRUB..."
    sudo cp "$grub_config" "$grub_config.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Configurar el tema
    if grep -q "^GRUB_THEME=" "$grub_config"; then
        print_info "Actualizando configuración existente del tema..."
        sudo sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"$theme_path\"|" "$grub_config"
    elif grep -q "^#GRUB_THEME=" "$grub_config"; then
        print_info "Descomentando y configurando el tema..."
        sudo sed -i "s|^#GRUB_THEME=.*|GRUB_THEME=\"$theme_path\"|" "$grub_config"
    else
        print_info "Añadiendo configuración del tema..."
        echo "GRUB_THEME=\"$theme_path\"" | sudo tee -a "$grub_config" > /dev/null
    fi
    
    # Configuraciones adicionales para mejorar la experiencia visual
    print_info "Aplicando configuraciones adicionales..."
    
    # Asegurar que el terminal de GRUB tenga resolución adecuada
    if ! grep -q "^GRUB_GFXMODE=" "$grub_config"; then
        echo "GRUB_GFXMODE=auto" | sudo tee -a "$grub_config" > /dev/null
    fi
    
    # Configurar tiempo de espera si no está configurado
    if ! grep -q "^GRUB_TIMEOUT=" "$grub_config"; then
        echo "GRUB_TIMEOUT=5" | sudo tee -a "$grub_config" > /dev/null
    fi
    
    print_success "Configuración de GRUB actualizada"
}

# Función para regenerar la configuración de GRUB
regenerate_grub() {
    print_info "Regenerando configuración de GRUB..."
    
    # Detectar el comando correcto para regenerar GRUB
    if command -v grub-mkconfig &> /dev/null; then
        local grub_cfg="$GRUB_DIR/grub.cfg"
        sudo grub-mkconfig -o "$grub_cfg"
    elif command -v grub2-mkconfig &> /dev/null; then
        local grub_cfg="$GRUB_DIR/grub.cfg"
        sudo grub2-mkconfig -o "$grub_cfg"
    else
        print_error "No se pudo encontrar grub-mkconfig o grub2-mkconfig"
        exit 1
    fi
    
    print_success "Configuración de GRUB regenerada correctamente"
}

# Función para limpiar archivos temporales
cleanup() {
    print_info "Limpiando archivos temporales..."
    
    # Limpiar directorio temporal si existe
    if [ -n "$EXTRACT_DIR" ] && [ -d "$EXTRACT_DIR" ]; then
        print_info "Eliminando directorio temporal: $EXTRACT_DIR"
        rm -rf "$EXTRACT_DIR"
        print_success "Archivos temporales eliminados"
    else
        print_info "No hay archivos temporales que limpiar"
    fi
}

# Función principal
main() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}  Instalador del tema hyperfluent-arch${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo
    
    # Verificaciones iniciales
    check_root
    check_dependencies
    check_theme_file
    
    # Detectar configuración del sistema
    detect_grub_location
    
    if detect_luks; then
        print_info "Configuración detectada: Sistema con LUKS"
        print_warning "Se aplicarán configuraciones específicas para sistemas cifrados"
    else
        print_info "Configuración detectada: Sistema sin LUKS"
    fi
    
    echo
    print_info "Iniciando instalación del tema..."
    echo
    
    # Proceso de instalación
    extract_theme
    install_theme
    configure_grub
    regenerate_grub
    
    echo
    print_success "¡Tema hyperfluent-arch instalado correctamente!"
    print_info "El tema se aplicará en el próximo reinicio"
    print_info "Ubicación del tema: $GRUB_DIR/themes/hyperfluent-arch"
    
    if detect_luks; then
        print_info "Para sistemas LUKS: El tema será visible después de ingresar la contraseña de cifrado"
    fi
    
    echo
    cleanup
    
    echo
    print_success "Instalación completada. ¡Disfruta tu nuevo tema de GRUB!"
}

# Ejecutar función principal
main "$@"

