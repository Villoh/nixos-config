# NixOS + Hyprland + DMS — runbook para el agente

## Objetivo

Convertir la instalación actual en una configuración reproducible con flakes, Hyprland y Dank Material Shell (DMS), conservando Plasma como sesión de respaldo.

## Estado actual

- NixOS 26.05 arranca correctamente.
- Disco raíz: LUKS + ext4.
- Escritorio actual: KDE Plasma con SDDM.
- Desktop: sin swap en disco; usar zram.
- No reutilizar `hardware-configuration.nix` en otro equipo.

## Propiedad de la configuración

| Repositorio | Debe gestionar |
| --- | --- |
| `~/src/nixos-config` | NixOS, hardware, paquetes, servicios, zram, Hyprland y DMS |
| chezmoi | Dotfiles portables, scripts y plantillas de secretos |

Un archivo solo puede pertenecer a NixOS/Home Manager o a chezmoi, nunca a ambos.

## 1. Crear el repositorio base

```bash
mkdir -p ~/src/nixos-config
sudo cp -a /etc/nixos/. ~/src/nixos-config/
sudo chown -R "$USER":"$(id -gn)" ~/src/nixos-config

cd ~/src/nixos-config
nix-shell -p git nodejs_24 gh
git init -b main
git add configuration.nix hardware-configuration.nix
git commit -m "chore: working NixOS Plasma installation"
```

`nix-shell` abre un entorno temporal con Git, Node.js y GitHub CLI. No los instala permanentemente.

## 2. Ejecutar el agente

El paquete anterior `@mariozechner/pi-coding-agent` está obsoleto. Usar:

```bash
npm_config_ignore_scripts=true npx --yes \
  --package=@earendil-works/pi-coding-agent@latest \
  pi
```

Ejecutarlo desde `~/src/nixos-config`. El agente solo edita el repositorio; no debe aplicar cambios por su cuenta.

## 3. Encargo para el agente

```text
Convierte este repositorio NixOS en una flake multi-host reproducible.

Estado: NixOS 26.05, Plasma/SDDM funcionando, raíz LUKS+ext4 y sin swap en disco.

Haz lo siguiente:
1. Conserva la configuración actual como host desktop.
2. No modifiques ni inventes el contenido de hardware-configuration.nix.
3. Mantén Plasma y SDDM como respaldo.
4. Añade Hyprland declarativamente.
5. Integra Dank Material Shell mediante su flake y módulo oficial de Home Manager.
6. Activa zram para desktop.
7. Separa módulos comunes, desktop y futuros ajustes de portátil.
8. Añade README con comandos de validación, aplicación y rollback.
9. Formatea los archivos Nix y ejecuta las comprobaciones disponibles.

Restricciones:
- No uses curl | sh ni instaladores imperativos.
- No gestiones con Home Manager archivos que pertenezcan a chezmoi.
- No ejecutes nixos-rebuild switch, no borres archivos y no cambies particiones.
- Detente y explica cualquier decisión que afecte al arranque, LUKS o SDDM.
```

## 4. Estructura objetivo

```text
nixos-config/
├── flake.nix
├── flake.lock
├── hosts/
│   ├── desktop/
│   │   ├── default.nix
│   │   └── hardware-configuration.nix
│   └── zenbook/                 # más adelante
├── modules/
│   ├── common.nix
│   ├── plasma.nix
│   ├── hyprland.nix
│   └── zram.nix
├── home/
│   └── dms.nix
└── README.md
```

La flake de DMS debe apuntar al proyecto oficial:

```nix
inputs.dms.url = "github:AvengeMedia/DankMaterialShell";
```

Y Home Manager debe importar su módulo oficial:

```nix
imports = [ inputs.dms.homeModules.dank-material-shell ];
```

## 5. Revisar y probar

Primero revisar el diff:

```bash
cd ~/src/nixos-config
git diff --stat
git diff
```

Después validar sin cambiar el arranque permanente:

```bash
nix flake check
sudo nixos-rebuild test --flake .#desktop
```

Comprobar en la configuración temporal:

- Plasma sigue abriendo.
- SDDM ofrece Hyprland.
- Hyprland inicia y DMS aparece.
- Funcionan red, audio, Bluetooth, notificaciones, bloqueo y portales Wayland.
- `zramctl` y `swapon --show` muestran zram.

Solo cuando todo funcione:

```bash
sudo nixos-rebuild switch --flake .#desktop
git add .
git commit -m "feat: add reproducible Hyprland and DMS setup"
```

## 6. Recuperación

- En SDDM, entrar en Plasma si Hyprland falla.
- En el menú de arranque, elegir una generación anterior.
- Desde una TTY, probar una corrección con `nixos-rebuild test` antes de `switch`.

## 7. Zenbook más adelante

1. Clonar el mismo repositorio.
2. Generar y conservar su propio `hardware-configuration.nix`.
3. Crear el host `zenbook`; no copiar el hardware del desktop.
4. Añadir configuración específica de energía, suspensión e hibernación.
5. Para hibernar, usar swap persistente cifrada; zram por sí sola no sirve.

## Criterio de terminado

- `nix flake check` pasa.
- Desktop arranca tras reiniciar y desbloquea LUKS.
- Plasma y Hyprland aparecen en SDDM.
- DMS funciona dentro de Hyprland.
- zram está activa y no hay swap en disco en el desktop.
- El repositorio contiene instrucciones de rollback y está versionado en Git.
