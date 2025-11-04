#!/bin/bash
# Instalador VPN Formosa - FortiVPN Client
# Compatible con Ubuntu, Debian, Pop!_OS y derivados

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo ""
echo "==========================================="
echo "   VPN Formosa - Instalador"
echo "==========================================="
echo ""

# Verificar que se ejecuta con permisos normales (no root)
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}❌ No ejecutes este script como root o con sudo${NC}"
    echo "Ejecuta: bash install.sh"
    exit 1
fi

# Verificar que openfortivpn está instalado
if ! command -v openfortivpn &> /dev/null; then
    echo -e "${RED}❌ openfortivpn no está instalado${NC}"
    echo ""
    echo "Instálalo con:"
    echo "  sudo apt update"
    echo "  sudo apt install openfortivpn"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓${NC} openfortivpn encontrado"
echo ""

# Solicitar credenciales
echo -e "${BLUE}Configuración de credenciales:${NC}"
echo ""

read -p "Usuario VPN: " VPN_USER

while true; do
    read -s -p "Contraseña VPN: " VPN_PASS
    echo ""
    read -s -p "Confirmar contraseña: " VPN_PASS2
    echo ""
    
    if [ "$VPN_PASS" = "$VPN_PASS2" ]; then
        break
    else
        echo -e "${RED}Las contraseñas no coinciden. Intenta de nuevo.${NC}"
        echo ""
    fi
done

# Escapar caracteres especiales en la contraseña para el archivo de configuración
VPN_PASS_ESCAPED=$(printf '%s\n' "$VPN_PASS" | sed 's/[&/\]/\\&/g')

echo ""
echo -e "${BLUE}[1/5]${NC} Creando directorios..."

# Crear directorio de configuración si no existe
sudo mkdir -p /etc/openfortivpn
echo -e "${GREEN}✓${NC} Directorio creado"

echo -e "${BLUE}[2/5]${NC} Creando archivo de configuración..."

# Crear el archivo de configuración
sudo tee /etc/openfortivpn/formosa.conf > /dev/null << EOF
host = conexion.formosa.gob.ar
port = 10443
username = $VPN_USER
password = $VPN_PASS_ESCAPED
trusted-cert = 
set-dns = 1
pppd-use-peerdns = 1
EOF

sudo chmod 600 /etc/openfortivpn/formosa.conf
echo -e "${GREEN}✓${NC} Configuración creada y asegurada (permisos 600)"

echo -e "${BLUE}[3/5]${NC} Creando servicio systemd..."

# Crear el servicio systemd
sudo tee /etc/systemd/system/vpn-formosa.service > /dev/null << 'EOF'
[Unit]
Description=VPN Formosa - FortiVPN
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/openfortivpn -c /etc/openfortivpn/formosa.conf
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
echo -e "${GREEN}✓${NC} Servicio systemd creado"

echo -e "${BLUE}[4/5]${NC} Creando scripts de control..."

# Script principal de control
cat > ~/vpn << 'EOFSCRIPT'
#!/bin/bash

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

case "$1" in
    ""|on|conectar|start)
        echo -e "${GREEN}🟢 Conectando VPN Formosa...${NC}"
        sudo systemctl start vpn-formosa.service
        sleep 3
        if systemctl is-active --quiet vpn-formosa.service; then
            IP=$(ip addr show ppp0 2>/dev/null | grep "inet " | awk '{print $2}')
            echo -e "${GREEN}✅ VPN CONECTADA${NC}"
            if [ -n "$IP" ]; then
                echo -e "   IP: ${BLUE}$IP${NC}"
            fi
        else
            echo -e "${RED}❌ Error al conectar${NC}"
            echo "Ver logs: vpn logs"
        fi
        ;;
    
    off|desconectar|stop)
        echo -e "${RED}🔴 Desconectando VPN...${NC}"
        sudo systemctl stop vpn-formosa.service
        sleep 1
        echo -e "${GREEN}✅ VPN desconectada${NC}"
        ;;
    
    estado|status|-e)
        if systemctl is-active --quiet vpn-formosa.service; then
            echo -e "${GREEN}🟢 VPN CONECTADA${NC}"
            IP=$(ip addr show ppp0 2>/dev/null | grep "inet " | awk '{print $2}')
            if [ -n "$IP" ]; then
                echo -e "   IP: ${BLUE}$IP${NC}"
            fi
            UPTIME=$(systemctl show vpn-formosa.service --property=ActiveEnterTimestamp --value)
            if [ -n "$UPTIME" ]; then
                echo -e "   Conectado desde: $UPTIME"
            fi
        else
            echo -e "${RED}🔴 VPN DESCONECTADA${NC}"
        fi
        ;;
    
    restart|reiniciar)
        echo -e "${YELLOW}🔄 Reiniciando VPN...${NC}"
        sudo systemctl restart vpn-formosa.service
        sleep 3
        if systemctl is-active --quiet vpn-formosa.service; then
            echo -e "${GREEN}✅ VPN reiniciada${NC}"
        else
            echo -e "${RED}❌ Error al reiniciar${NC}"
            echo "Ver logs: vpn logs"
        fi
        ;;
    
    logs)
        echo "Logs de VPN Formosa (Ctrl+C para salir):"
        echo "=========================================="
        sudo journalctl -u vpn-formosa.service -n 50 -f
        ;;
    
    auto-on)
        echo -e "${GREEN}Habilitando inicio automático...${NC}"
        sudo systemctl enable vpn-formosa.service
        echo -e "${GREEN}✅ VPN se iniciará automáticamente al encender el PC${NC}"
        ;;
    
    auto-off)
        echo -e "${YELLOW}Deshabilitando inicio automático...${NC}"
        sudo systemctl disable vpn-formosa.service
        echo -e "${GREEN}✅ VPN NO se iniciará automáticamente${NC}"
        ;;
    
    help|ayuda|-h|--help)
        echo "VPN Formosa - Cliente FortiVPN"
        echo ""
        echo "Uso: vpn [comando]"
        echo ""
        echo "Comandos disponibles:"
        echo "  (sin comando)    Conectar VPN"
        echo "  on/conectar      Conectar VPN"
        echo "  off/desconectar  Desconectar VPN"
        echo "  estado/-e        Ver estado de la VPN"
        echo "  restart          Reiniciar VPN"
        echo "  logs             Ver logs en tiempo real"
        echo "  auto-on          Habilitar inicio automático"
        echo "  auto-off         Deshabilitar inicio automático"
        echo "  help             Mostrar esta ayuda"
        echo ""
        echo "Ejemplos:"
        echo "  vpn              # Conectar"
        echo "  vpn estado       # Ver estado"
        echo "  vpn off          # Desconectar"
        ;;
    
    *)
        echo -e "${RED}❌ Comando desconocido: $1${NC}"
        echo "Usa 'vpn help' para ver comandos disponibles"
        exit 1
        ;;
esac
EOFSCRIPT

chmod +x ~/vpn
echo -e "${GREEN}✓${NC} Script vpn creado en ~/vpn"

# Crear alias en bashrc si no existe
if ! grep -q "alias vpn=" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# Alias para VPN Formosa" >> ~/.bashrc
    echo "alias vpn='~/vpn'" >> ~/.bashrc
    echo -e "${GREEN}✓${NC} Alias agregado a ~/.bashrc"
else
    echo -e "${YELLOW}⚠${NC}  Alias 'vpn' ya existe en ~/.bashrc"
fi

echo -e "${BLUE}[5/5]${NC} Obteniendo certificado del servidor..."
echo ""

# Intentar conectar para obtener el certificado
echo -e "${YELLOW}Se intentará una conexión para obtener el certificado...${NC}"
echo "Presiona Ctrl+C después de ver el mensaje de error del certificado"
echo ""
sleep 2

# Capturar el certificado
CERT_OUTPUT=$(sudo openfortivpn conexion.formosa.gob.ar:10443 -u "$VPN_USER" 2>&1 || true)
CERT_HASH=$(echo "$CERT_OUTPUT" | grep "trusted-cert" | head -1 | awk '{print $NF}')

if [ -n "$CERT_HASH" ]; then
    echo -e "${GREEN}✓${NC} Certificado obtenido: $CERT_HASH"
    # Actualizar el archivo de configuración con el certificado
    sudo sed -i "s/^trusted-cert = $/trusted-cert = $CERT_HASH/" /etc/openfortivpn/formosa.conf
    echo -e "${GREEN}✓${NC} Certificado agregado a la configuración"
else
    echo -e "${YELLOW}⚠${NC}  No se pudo obtener el certificado automáticamente"
    echo "Lo obtendrás en la primera conexión manual"
fi

echo ""
echo "==========================================="
echo -e "${GREEN}   ✅ INSTALACIÓN COMPLETA${NC}"
echo "==========================================="
echo ""
echo "Comandos disponibles:"
echo -e "  ${BLUE}vpn${NC}              → Conectar VPN"
echo -e "  ${BLUE}vpn off${NC}          → Desconectar VPN"
echo -e "  ${BLUE}vpn estado${NC}       → Ver estado"
echo -e "  ${BLUE}vpn logs${NC}         → Ver logs"
echo -e "  ${BLUE}vpn help${NC}         → Ver todos los comandos"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo "1. Recarga tu terminal: ${BLUE}source ~/.bashrc${NC}"
echo "2. O abre una nueva terminal"
echo "3. Luego ejecuta: ${BLUE}vpn${NC}"
echo ""
echo -e "${YELLOW}🔒 Seguridad:${NC}"
echo "Tu contraseña está en: /etc/openfortivpn/formosa.conf"
echo "Solo accesible por root (permisos 600)"
echo ""
