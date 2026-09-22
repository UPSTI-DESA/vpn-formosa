#!/bin/bash
#
# Desinstalador VPN Formosa (multi-perfil)
# Autor: Gaston Schneider <gassstonn@gmail.com>
# Licencia: MIT

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

CONF_DIR=/etc/openfortivpn

echo ""
echo "==========================================="
echo "   VPN Formosa - Desinstalador"
echo "==========================================="
echo ""

if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ No ejecutes este script como root o con sudo${NC}"
    echo "Ejecuta: bash uninstall.sh"
    exit 1
fi

echo -e "${YELLOW}⚠️  ATENCIÓN:${NC}"
echo "Esto eliminará completamente el cliente VPN Formosa:"
echo "  • Servicios systemd (todos los perfiles)"
echo "  • TODOS los perfiles de $CONF_DIR (incluyendo credenciales)"
echo "  • Script de control y comando /usr/local/bin/vpn"
echo "  • Alias de bash"
echo ""
echo -e "${YELLOW}Si tenés otros configs de openfortivpn en $CONF_DIR, se borrarán también.${NC}"
echo ""

read -p "¿Estás seguro que deseas continuar? (s/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo "Desinstalación cancelada"
    exit 0
fi

echo ""
echo -e "${RED}[1/5]${NC} Deteniendo y deshabilitando servicios..."

for unit in $(systemctl list-units --type=service --all --no-legend 'vpn-formosa@*' 2>/dev/null | awk '{print $1}'); do
    sudo systemctl stop "$unit" 2>/dev/null || true
    sudo systemctl disable "$unit" 2>/dev/null || true
    echo -e "${GREEN}✓${NC} $unit detenido/deshabilitado"
done
for unit in vpn-formosa.service; do
    if systemctl is-active --quiet "$unit" 2>/dev/null; then
        sudo systemctl stop "$unit" 2>/dev/null || true
    fi
    if systemctl is-enabled --quiet "$unit" 2>/dev/null; then
        sudo systemctl disable "$unit" 2>/dev/null || true
    fi
done

echo -e "${RED}[2/5]${NC} Eliminando servicios systemd..."

sudo rm -f /etc/systemd/system/vpn-formosa@.service
sudo rm -f /etc/systemd/system/vpn-formosa.service
sudo systemctl daemon-reload
echo -e "${GREEN}✓${NC} Servicios eliminados"

echo -e "${RED}[3/5]${NC} Eliminando perfiles y configuración..."

if [ -d "$CONF_DIR" ]; then
    sudo rm -f "$CONF_DIR"/*.conf "$CONF_DIR"/default-profile
    if [ -z "$(ls -A "$CONF_DIR" 2>/dev/null)" ]; then
        sudo rmdir "$CONF_DIR" 2>/dev/null || true
    fi
    echo -e "${GREEN}✓${NC} Perfiles eliminados"
else
    echo -e "${YELLOW}⚠${NC}  Directorio no encontrado"
fi

echo -e "${RED}[4/5]${NC} Eliminando comando y scripts..."

sudo rm -f /usr/local/bin/vpn
rm -f ~/vpn 2>/dev/null || true
echo -e "${GREEN}✓${NC} Comando 'vpn' eliminado"

echo -e "${RED}[5/5]${NC} Eliminando alias de bash..."

if grep -q "alias vpn=" ~/.bashrc 2>/dev/null; then
    cp ~/.bashrc ~/.bashrc.backup
    sed -i '/# Alias para VPN Formosa/d; /alias vpn=/d' ~/.bashrc
    echo -e "${GREEN}✓${NC} Alias eliminado (backup en ~/.bashrc.backup)"
else
    echo -e "${YELLOW}⚠${NC}  Alias no encontrado en ~/.bashrc"
fi

echo ""
echo "==========================================="
echo -e "${GREEN}   ✅ DESINSTALACIÓN COMPLETA${NC}"
echo "==========================================="
echo ""
echo "Si deseas reinstalarlo:"
echo "  git clone https://github.com/UPSTI-DESA/vpn-formosa.git"
echo "  cd vpn-formosa"
echo "  bash install.sh"
echo ""
echo -e "${YELLOW}Nota:${NC} Recargá tu terminal con: ${GREEN}source ~/.bashrc${NC}"
echo ""
