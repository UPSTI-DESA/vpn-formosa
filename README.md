# VPN Formosa - Cliente FortiVPN para Linux

Cliente de línea de comandos para conectarse a la red del Gobierno de Formosa usando
[OpenFortiVPN](https://github.com/adrienverge/openfortivpn) en Linux.

Soporta **múltiples usuarios/perfiles**: podés guardar varias credenciales y alternar
entre ellas sin volver a escribir nada.

## ✨ Características

- ✅ Instalación automática en un solo comando
- ✅ **Multi-perfil**: varios usuarios VPN en la misma PC
- ✅ Menú interactivo con atajos de teclado
- ✅ Gestión mediante systemd (servicio del sistema)
- ✅ Reconexión automática si el túnel se cae
- ✅ Inicio automático al encender el PC (opcional)
- ✅ Logs organizados del sistema
- ✅ Las contraseñas quedan solo en root (permisos 600)

## 📋 Requisitos

- Linux (Ubuntu, Debian, Pop!_OS, etc.)
- Acceso `sudo`
- Credenciales VPN del Gobierno de Formosa

## 🔧 Instalación

```bash
sudo apt update
sudo apt install openfortivpn git

git clone https://github.com/UPSTI-DESA/vpn-formosa.git
cd vpn-formosa
bash install.sh
```

El instalador te pedirá:

1. **Nombre del perfil** (por defecto `principal`)
2. **Usuario VPN**
3. **Contraseña**

Y deja todo listo: el comando `vpn` en `/usr/local/bin/vpn`, el servicio systemd
multi-perfil y el perfil predeterminado configurado.

## 💻 Uso

### Menú interactivo (recomendado)

```bash
vpn
```

```
============================================================
  VPN FORMOSA   ● principal ACTIVO   IP: 192.168.251.3
============================================================

   [1] Perfiles (2)
   [2] Agregar perfil
   [3] Eliminar perfil
   [4] Ver logs
   [5] Reiniciar perfil
   [6] Estado detallado
   [q] Salir

   Opción:
```

Al elegir un perfil, el menú se cierra, muestra el progreso de conexión y termina.

En el submenú **Perfiles**: `1-9` para elegir, `n`/`p` para pasar de página, `b` para volver.

Al ver los **logs** (`[4]`), se abre un visor: presioná **`q`** para salir.

### Comandos

| Comando | Descripción |
|---------|-------------|
| `vpn` | Menú interactivo |
| `vpn on [perfil]` | Conectar (sin perfil: conecta el **último usado**) |
| `vpn off [perfil]` | Desconectar un perfil (sin perfil: todos) |
| `vpn estado [perfil]` | Ver estado |
| `vpn restart [perfil]` | Reiniciar un perfil |
| `vpn logs [perfil]` | Ver logs (`q` para salir) |
| `vpn perfiles` | Listar perfiles |
| `vpn add <perfil>` | Agregar un nuevo usuario/perfil |
| `vpn rm <perfil>` | Eliminar un perfil (no el base) |
| `vpn auto-on [perfil]` | Habilitar inicio automático |
| `vpn auto-off [perfil]` | Deshabilitar inicio automático |
| `vpn help` | Ayuda |

### Perfil predeterminado

`vpn on` sin argumentos conecta el **último perfil que usaste**. Ese dato se guarda en
`~/.cache/vpn/last-profile`. El orden de prioridad es:

1. Variable de entorno `VPN_DEFAULT_PROFILE`
2. Último perfil conectado
3. Archivo `/etc/openfortivpn/default-profile`
4. Primer perfil encontrado

### Ejemplos

```bash
vpn                    # Menú
vpn on                 # Conectar el perfil predeterminado
vpn add juan           # Crear un segundo perfil (pide usuario/contraseña)
vpn on juan            # Conectar el perfil 'juan'
vpn perfiles           # Ver todos los perfiles
vpn off                # Desconectar todo
```

## 🔒 Seguridad

Cada perfil se guarda en `/etc/openfortivpn/<perfil>.conf` con permisos **600**
(solo root). El perfil predeterminado se indica en `/etc/openfortivpn/default-profile`.

Recomendaciones:
- No compartas los archivos de `/etc/openfortivpn/`.
- Para cambiar una contraseña, editá el `.conf` correspondiente o volvé a crear el perfil.

## 🐛 Solución de problemas

### Ver logs de un perfil

```bash
vpn logs <perfil>
# o directo:
sudo journalctl -u vpn-formosa@<perfil>.service -f
```

### Error de certificado

En la primera conexión OpenFortiVPN puede pedir aceptar el certificado. El instalador
intenta obtenerlo automáticamente; si falla, conectá una vez manualmente:

```bash
sudo openfortivpn -c /etc/openfortivpn/<perfil>.conf
```

Copiá el hash que aparece en el mensaje `trusted-cert` y agregalo al `.conf`:

```
trusted-cert = HASH_DEL_CERTIFICADO
```

### La VPN no conecta

El comando `vpn on` ya limpia el servicio si el túnel no se establece, así que podés
reintentar directamente. Si persiste, mirá los logs con `vpn logs <perfil>`.

### Evitar el pedido de contraseña de sudo

Opcional: permitir administrar solo los servicios de la VPN sin contraseña.

```bash
sudo tee /etc/sudoers.d/vpn-formosa >/dev/null <<EOF
$USER ALL=(root) NOPASSWD: /usr/bin/systemctl start vpn-formosa@*, \
/usr/bin/systemctl stop vpn-formosa@*, \
/usr/bin/systemctl restart vpn-formosa@*, \
/usr/bin/systemctl enable vpn-formosa@*, \
/usr/bin/systemctl disable vpn-formosa@*, \
/usr/bin/systemctl status vpn-formosa@*, \
/usr/bin/journalctl -u vpn-formosa@*
EOF
sudo chmod 440 /etc/sudoers.d/vpn-formosa
```

## 🗑️ Desinstalación

```bash
bash uninstall.sh
```

Elimina los servicios, los perfiles/credenciales, el comando `vpn` y los alias.

## 📄 Licencia

MIT - ver [LICENSE](LICENSE).

## 🔗 Enlaces

- [OpenFortiVPN](https://github.com/adrienverge/openfortivpn)
