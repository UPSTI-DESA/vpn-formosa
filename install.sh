#!/bin/bash
# Instalador VPN Formosa - Cliente FortiVPN multi-perfil
# Compatible con Ubuntu, Debian, Pop!_OS y derivados

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SRC_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "==========================================="
echo "   VPN Formosa - Instalador"
echo "==========================================="
echo ""

if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}❌ No ejecutes este script como root o con sudo${NC}"
    echo "Ejecuta: bash install.sh"
    exit 1
fi

if ! command -v openfortivpn &> /dev/null; then
    echo -e "${RED}❌ openfortivpn no está instalado${NC}"
    echo ""
    echo "Instálalo con:"
    echo "  sudo apt update && sudo apt install openfortivpn"
    echo ""
    exit 1
fi
echo -e "${GREEN}✓${NC} openfortivpn encontrado"
echo ""

# ---------- Datos del perfil base ----------

echo -e "${BLUE}Configuración de tu primer perfil:${NC}"
echo ""

read -p "Nombre del perfil [principal]: " VPN_PROFILE
VPN_PROFILE="${VPN_PROFILE:-principal}"
if ! [[ "$VPN_PROFILE" =~ ^[A-Za-z0-9._-]+$ ]]; then
    echo -e "${RED}❌ Nombre inválido. Usá solo letras, números, punto, guión o guión bajo.${NC}"
    exit 1
fi

read -p "Usuario VPN: " VPN_USER
if [ -z "$VPN_USER" ]; then
    echo -e "${RED}❌ El usuario no puede estar vacío${NC}"
    exit 1
fi

while true; do
    read -s -p "Contraseña VPN: " VPN_PASS; echo ""
    read -s -p "Confirmar contraseña: " VPN_PASS2; echo ""
    if [ "$VPN_PASS" = "$VPN_PASS2" ]; then
        break
    fi
    echo -e "${RED}Las contraseñas no coinciden. Intenta de nuevo.${NC}"
done

CONF_DIR=/etc/openfortivpn
CONF_FILE="$CONF_DIR/$VPN_PROFILE.conf"

echo ""
echo -e "${BLUE}[1/6]${NC} Preparando directorios..."

sudo mkdir -p "$CONF_DIR"
TRUSTED_CERT=""
if [ -f "$CONF_FILE" ]; then
    TRUSTED_CERT=$(sudo awk -F ' = ' '/^trusted-cert =/ {print $2; exit}' "$CONF_FILE")
    sudo install -m 600 "$CONF_FILE" "$CONF_FILE.backup-$(date +%Y%m%d-%H%M%S)"
    echo -e "${GREEN}✓${NC} Copia de seguridad del perfil anterior creada"
fi
echo -e "${GREEN}✓${NC} Directorio listo"

echo -e "${BLUE}[2/6]${NC} Creando perfil '$VPN_PROFILE'..."

sudo tee "$CONF_FILE" > /dev/null << EOF
host = conexion.formosa.gob.ar
port = 10443
username = $VPN_USER
password = $VPN_PASS
trusted-cert = $TRUSTED_CERT
set-dns = 1
pppd-use-peerdns = 1
EOF
sudo chmod 600 "$CONF_FILE"
echo "$VPN_PROFILE" | sudo tee "$CONF_DIR/default-profile" > /dev/null
echo -e "${GREEN}✓${NC} Perfil creado (permisos 600) y marcado como predeterminado"

echo -e "${BLUE}[3/6]${NC} Instalando servicio systemd (multi-perfil)..."

sudo install -m 644 "$SRC_DIR/vpn-formosa@.service" "/etc/systemd/system/vpn-formosa@.service"

# Desactivar servicio antiguo de un solo perfil si existía
if systemctl list-unit-files vpn-formosa.service &>/dev/null; then
    sudo systemctl disable vpn-formosa.service 2>/dev/null || true
    sudo systemctl stop vpn-formosa.service 2>/dev/null || true
fi
sudo systemctl daemon-reload
echo -e "${GREEN}✓${NC} Servicio instalado"

echo -e "${BLUE}[4/6]${NC} Instalando comando 'vpn'..."

sudo install -m 755 "$SRC_DIR/vpn" /usr/local/bin/vpn

# Quitar alias viejo si existía (ya no es necesario)
if grep -q "alias vpn=" ~/.bashrc 2>/dev/null; then
    sed -i '/# Alias para VPN Formosa/d; /alias vpn=/d' ~/.bashrc
    echo -e "${GREEN}✓${NC} Alias antiguo eliminado de ~/.bashrc"
fi
echo -e "${GREEN}✓${NC} Comando disponible en /usr/local/bin/vpn"

echo -e "${BLUE}[5/6]${NC} Obteniendo certificado del servidor..."
echo ""
echo -e "${YELLOW}Se intentará una conexión para obtener el certificado...${NC}"
sleep 1
CERT_OUTPUT=$(sudo timeout 15 openfortivpn conexion.formosa.gob.ar:10443 -u "$VPN_USER" 2>&1 || true)
CERT_HASH=$(echo "$CERT_OUTPUT" | grep "trusted-cert" | head -1 | awk '{print $NF}')
if [ -n "$CERT_HASH" ]; then
    echo -e "${GREEN}✓${NC} Certificado obtenido: $CERT_HASH"
    sudo sed -i "s/^trusted-cert = .*/trusted-cert = $CERT_HASH/" "$CONF_FILE"
else
    echo -e "${YELLOW}⚠${NC}  No se pudo obtener automáticamente; se completará en la primera conexión"
fi

echo -e "${BLUE}[6/6]${NC} Verificando..."

echo ""
echo "==========================================="
echo -e "${GREEN}   ✅ INSTALACIÓN COMPLETA${NC}"
echo "==========================================="
echo ""
echo "Uso rápido:"
echo -e "  ${BLUE}vpn${NC}              → Menú interactivo"
echo -e "  ${BLUE}vpn on${NC}           → Conectar perfil '$VPN_PROFILE'"
echo -e "  ${BLUE}vpn off${NC}          → Desconectar todo"
echo -e "  ${BLUE}vpn add <perfil>${NC} → Agregar otro usuario VPN"
echo -e "  ${BLUE}vpn help${NC}         → Ver todos los comandos"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo "1. Abrí una terminal nueva (o ejecutá: source ~/.bashrc)"
echo "2. Luego ejecutá: vpn"
echo ""
echo -e "${YELLOW}🔒 Seguridad:${NC}"
echo "Las contraseñas están en $CONF_DIR/<perfil>.conf (solo root, permisos 600)"
echo ""
