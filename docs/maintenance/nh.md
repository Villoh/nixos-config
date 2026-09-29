# `nh`: operaciones diarias

`nh` es un CLI para tareas comunes de Nix, NixOS y Home Manager. En este
repositorio está instalado como paquete de usuario en
`modules/home/shell/packages.nix`. Es una interfaz para evaluar, construir y
activar la configuración; no cambia cómo se declara ni sustituye al flake.

Al construir, `nh` muestra progreso del build y un diff de cambios, y puede
pedir confirmación antes de activar. El build sigue usando configuración y
paquetes declarados por el repositorio.

## Seleccionar este flake y host

El paquete está instalado, pero este repositorio no establece un flake por
defecto para `nh`. Actualmente `flake.nix` declara solo `desktop`; Zenbook no
es destino de build hasta generar su archivo de hardware y añadir host al flake.
Ejecuta comandos desde la raíz del checkout y pasa ruta y host explícitamente:

```bash
cd /home/mikel/src/nixos-config
nh os build . -H desktop
```

`-H desktop` selecciona `nixosConfigurations.desktop`; `.` identifica el flake
en el directorio actual. Revisa siempre que estás en checkout y host correctos.

## Construir, probar y activar

Elige el comando según efecto deseado:

```bash
nh os build . -H desktop
nh os test . -H desktop
nh os switch . -H desktop
```

- `build`: construye sin activar.
- `test`: activa configuración en ejecución, pero no la convierte en
  predeterminada del próximo arranque. Útil para probar y revertir con reboot.
- `switch`: activa configuración y la establece como predeterminada de
  arranque. Requiere autorización administrativa.
- `boot`: construye y establece como predeterminada del arranque sin activar
  inmediatamente la sesión actual.

Después de `test`, revisa sesión gráfica, red, audio, Bluetooth y portales
Wayland. Si algo falla, reinicia o sigue [Recuperación](recovery.md). Ejecuta
`nix flake check` antes de construir cambios de configuración. No uses `switch`
hasta validar y probar cambios.

## Otras operaciones

```bash
nh os info
nh os rollback
nh search <nombre-paquete>
nh clean all --dry
```

`info` lista generaciones del perfil del sistema; `rollback` construye y activa
configuración anterior. `search` consulta paquetes. `clean` se describe con
advertencias y pasos de revisión en [Limpieza](cleanup.md). Puedes consultar
opciones disponibles con `nh os --help` y `nh clean all --help`.

## Diferencia respecto a `nixos-rebuild`

`nh os` ofrece interfaz y presentación distintas, pero los conceptos siguen
siendo generaciones NixOS. Usa `nixos-rebuild` si necesitas una opción que `nh`
aún no exponga. Para flujos de este host, ambos deben apuntar al mismo flake y
host; no mezcles una ruta o nombre de host incorrecto.
