# VPN Formosa - Cliente FortiVPN para Linux

Cliente profesional de VPN para conectarse a la red del Gobierno de Formosa usando FortiVPN en sistemas Linux.

## 🚀 Características

- ✅ Instalación automática en un solo comando
- ✅ Gestión mediante systemd (servicio del sistema)
- ✅ Sin mensajes molestos en terminal
- ✅ Comandos simples e intuitivos
- ✅ Logs organizados del sistema
- ✅ Reconexión automática si falla la conexión
- ✅ Soporte para inicio automático al encender el PC

## 📋 Requisitos

- Sistema operativo Linux (Ubuntu, Debian, Pop!_OS, etc.)
- Acceso sudo (permisos de administrador)
- Credenciales de acceso VPN proporcionadas por el Gobierno de Formosa

## 🔧 Instalación

### 1. Instalar dependencias

```bash
sudo apt update
sudo apt install openfortivpn git
```

### 2. Clonar el repositorio

```bash
git clone https://github.com/UPSTI-DESA/vpn-formosa.git
cd vpn-formosa
```

### 3. Ejecutar el instalador

```bash
bash install.sh
```

El instalador te pedirá:
- Tu nombre de usuario de la VPN
- Tu contraseña
- El certificado (se descarga automáticamente en la primera conexión)

### 4. Recargar tu terminal

```bash
source ~/.bashrc
```

o simplemente abre una nueva terminal.

## 💻 Uso

### Comandos disponibles

| Comando | Descripción |
|---------|-------------|
| `vpn` o `vpn on` | Conectar a la VPN |
| `vpn off` | Desconectar de la VPN |
| `vpn estado` | Ver estado de la conexión |
| `vpn restart` | Reiniciar la conexión |
| `vpn logs` | Ver logs en tiempo real |
| `vpn auto-on` | Habilitar inicio automático |
| `vpn auto-off` | Deshabilitar inicio automático |
| `vpn help` | Mostrar ayuda |

### Ejemplos de uso

**Conectar a la VPN:**
```bash
vpn
```

**Ver si estás conectado:**
```bash
vpn estado
```

**Desconectar:**
```bash
vpn off
```

**Ver logs si hay problemas:**
```bash
vpn logs
```

## 🔒 Seguridad

⚠️ **IMPORTANTE:** Tu contraseña se guarda en el archivo `/etc/openfortivpn/formosa.conf` con permisos restringidos (600), lo que significa que solo root puede leerla.

**Recomendaciones:**
- Cambia tu contraseña después de la primera instalación
- Actualiza el archivo de configuración con: `sudo nano /etc/openfortivpn/formosa.conf`
- No compartas tu archivo de configuración

## 🐛 Solución de problemas

### Error de autenticación

Si recibes el error "Could not authenticate to gateway":

1. Verifica tus credenciales:
```bash
sudo nano /etc/openfortivpn/formosa.conf
```

2. Asegúrate de que tu usuario y contraseña sean correctos

3. Si tu contraseña tiene caracteres especiales, prueba encerrarla entre comillas:
```
password = "tu_contraseña"
```

### Error de certificado

Si recibes un error sobre el certificado:

1. Conecta manualmente una vez para aceptar el certificado:
```bash
sudo openfortivpn -c /etc/openfortivpn/formosa.conf
```

2. Copia el hash del certificado que aparece en el error

3. Agrégalo al archivo de configuración:
```bash
sudo nano /etc/openfortivpn/formosa.conf
```

4. Añade la línea:
```
trusted-cert = HASH_DEL_CERTIFICADO
```

### Ver logs detallados

```bash
sudo journalctl -u vpn-formosa.service -f
```

### La VPN no se conecta

```bash
# Verificar el estado del servicio
sudo systemctl status vpn-formosa.service

# Reiniciar el servicio
vpn restart

# Ver logs completos
vpn logs
```

## 🗑️ Desinstalación

Para desinstalar completamente el cliente VPN:

```bash
bash uninstall.sh
```

Esto eliminará:
- El servicio systemd
- Los archivos de configuración
- Los scripts de control
- Los alias de bash

## 📝 Actualizar configuración

Si necesitas cambiar tu usuario o contraseña:

```bash
sudo nano /etc/openfortivpn/formosa.conf
```

Edita las líneas correspondientes y guarda. Luego reinicia:

```bash
vpn restart
```

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Haz fork del repositorio
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para más detalles.

## 📞 Soporte

Si tienes problemas:

1. Revisa la sección de [Solución de problemas](#-solución-de-problemas)
2. Abre un [Issue](https://github.com/UPSTI-DESA/vpn-formosa/issues) en GitHub
3. Contacta al administrador de sistemas de tu organización

## 🔗 Enlaces útiles

- [Documentación de OpenFortiVPN](https://github.com/adrienverge/openfortivpn)
- [Systemd Documentation](https://www.freedesktop.org/software/systemd/man/systemd.service.html)

---

**Desarrollado con ❤️ para facilitar el acceso remoto al Gobierno de Formosa**
