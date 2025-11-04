#!/bin/bash
# Desinstalador VPN Formosa

set -e

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "==========================================="
echo "   VPN Formosa - Desinstalador"
echo "==========================================="
echo ""

# Verificar que no se ejecuta como root
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}❌ No ejecutes este script como root o con sudo${NC}"
    echo "Ejecuta: bash uninstall.sh"
    exit 1
fi

echo -e "${YELLOW}⚠️  ATENCIÓN:${NC}"
echo "Esto eliminará completamente el cliente VPN Formosa:"
echo "  • Servicio systemd"
echo "  • Archivos de configuración (incluyendo credenciales)"
echo "  • Scripts de control"
echo "  • Alias de bash"
echo ""

read -p "¿Estás seguro que deseas continuar? (s/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Desinstalación cancelada"
    exit 0
fi

echo ""
echo -e "${RED}[1/5]${NC} Deteniendo y deshabilitando servicio..."

# Detener y deshabilitar el servicio
if systemctl is-active --quiet vpn-formosa.service 2>/dev/null; then
    sudo systemctl stop vpn-formosa.service
    echo -e "${GREEN}✓${NC} Servicio detenido"
fi

if systemctl is-enabled --quiet vpn-formosa.service 2>/dev/null; then
    sudo systemctl disable vpn-formosa.service
    echo -e "${GREEN}✓${NC} Servicio deshabilitado"
fi

echo -e "${RED}[2/5]${NC} Eliminando servicio systemd..."

# Eliminar el servicio
if [ -f /etc/systemd/system/vpn-formosa.service ]; then
    sudo rm /etc/systemd/system/vpn-formosa.service
    sudo systemctl daemon-reload
    echo -e "${GREEN}✓${NC} Servicio eliminado"
else
    echo -e "${YELLOW}⚠${NC}  Servicio no encontrado"
fi

echo -e "${RED}[3/5]${NC} Eliminando archivos de configuración..."

# Eliminar archivo de configuración
if [ -f /etc/openfortivpn/formosa.conf ]; then
    sudo rm /etc/openfortivpn/formosa.conf
    echo -e "${GREEN}✓${NC} Configuración eliminada"
else
    echo -e "${YELLOW}⚠${NC}  Configuración no encontrada"
fi

# Eliminar directorio si está vacío
if [ -d /etc/openfortivpn ] && [ -z "$(ls -A /etc/openfortivpn)" ]; then
    sudo rmdir /etc/openfortivpn
    echo -e "${GREEN}✓${NC} Directorio /etc/openfortivpn eliminado"
fi

echo -e "${RED}[4/5]${NC} Eliminando scripts..."

# Eliminar script de control
if [ -f ~/vpn ]; then
    rm ~/vpn
    echo -e "${GREEN}✓${NC} Script ~/vpn eliminado"
else
    echo -e "${YELLOW}⚠${NC}  Script ~/vpn no encontrado"
fi

echo -e "${RED}[5/5]${NC} Eliminando alias de bash..."

# Eliminar alias del bashrc
if grep -q "alias vpn=" ~/.bashrc 2>/dev/null; then
    # Crear backup
    cp ~/.bashrc ~/.bashrc.backup
    # Eliminar las líneas del alias
    sed -i '/# Alias para VPN Formosa/d' ~/.bashrc
    sed -i '/alias vpn=/d' ~/.bashrc
    echo -e "${GREEN}✓${NC} Alias eliminado (backup en ~/.bashrc.backup)"
else
    echo -e "${YELLOW}⚠${NC}  Alias no encontrado en ~/.bashrc"
fi

echo ""
echo "==========================================="
echo -e "${GREEN}   ✅ DESINSTALACIÓN COMPLETA${NC}"
echo "==========================================="
echo ""
echo "El cliente VPN Formosa ha sido eliminado completamente."
echo ""
echo "Si deseas reinstalarlo en el futuro:"
echo "  git clone https://github.com/TU_USUARIO/vpn-formosa.git"
echo "  cd vpn-formosa"
echo "  bash install.sh"
echo ""
echo -e "${YELLOW}Nota:${NC} Recarga tu terminal con: ${GREEN}source ~/.bashrc${NC}"
echo ""
