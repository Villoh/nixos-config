# Recuperación y generaciones

NixOS conserva generaciones del sistema para poder arrancar una versión
anterior. Este host usa systemd-boot y conserva como máximo cinco entradas,
según `boot.loader.systemd-boot.configurationLimit` en
`modules/nixos/core/boot.nix`. La limpieza del store puede eliminar
configuraciones antiguas: no la ejecutes mientras dependas de una generación
para recuperar el sistema.

## Antes de activar un cambio

Valida flake y activa temporalmente, sin convertir todavía la configuración en
defecto de arranque:

```bash
nix flake check
nh os test . -H desktop
```

Comprueba al menos login gráfico, red, audio, Bluetooth y portales Wayland.
`test` ayuda a detectar fallos de activación; reiniciar permite volver a la
generación previa. Cuando pruebas pasan, `nh os switch . -H desktop` activa el
cambio y establece nueva generación de arranque. Más detalle en [guía de nh](nh.md).

## El entorno gráfico no arranca

1. En menú systemd-boot selecciona generación anterior.
2. Si el sistema arranca, corrige la configuración en checkout.
3. Ejecuta validación y prueba temporal desde TTY:

```bash
cd /home/mikel/src/nixos-config
nix flake check
nh os test . -H desktop
```

4. Vuelve a probar sesión y servicios antes de aplicar cambio permanente.

La generación anterior permite recuperar acceso, pero no corrige error fuente.
No borres generaciones ni hagas `switch` hasta que configuración corregida
pase pruebas.

## Consultar o activar generación anterior

Lista generaciones del sistema:

```bash
nh os info
```

El menú de arranque es opción más conservadora: selecciona generación conocida
sin cambiar configuración declarativa. Si el sistema está funcionando y
necesitas revertir activo, `nh os rollback` activa generación anterior. Confirma
que sea la generación deseada y luego corrige o revierte cambios del checkout;
de lo contrario, siguiente despliegue puede volver a introducir el problema.

También puedes listar generaciones con Nix directamente:

```bash
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

## Recuperación desde TTY

Si el entorno gráfico falla pero sistema sigue arrancado, cambia a TTY, revisa
servicios y configuración. Para probar una corrección sin marcarla como
predeterminada:

```bash
cd /home/mikel/src/nixos-config
nix flake check
nh os test . -H desktop
```

Si falla test, revisa error del build o activación antes de reintentar. No uses
`switch` como método de diagnóstico.
