# Maintenance

Guías prácticas para actualizar, validar, desplegar, recuperar y limpiar este
sistema NixOS. Cada guía cubre un flujo por separado:

- [Actualizar sistema y aplicaciones](maintenance/updates.md): actualizar inputs
  del flake, apps declarativas, Tunnel Agent, perfiles manuales y Flatpak.
- [`nh`: construir y desplegar](maintenance/nh.md): qué hace `nh` y cómo usarlo
  en este repositorio.
- [Recuperación y generaciones](maintenance/recovery.md): probar cambios,
  arrancar generaciones anteriores y volver atrás.
- [Limpieza](maintenance/cleanup.md): revisar y limpiar generaciones, raíces
  del store y paquetes Flatpak sin perder opciones de rollback.

## Reglas generales

1. Revisar cambios antes de aplicarlos (`git diff`).
2. Ejecutar `nix flake check` tras cambios de configuración o inputs.
3. Probar cambios del sistema antes de hacerlos permanentes.
4. Mantener generaciones antiguas hasta confirmar que sistema funciona.
5. No ejecutar `nixos-rebuild switch` ni limpieza destructiva automáticamente.

## Instalación de hosts

- [Desktop installation](installation-desktop.md): host existente `desktop`.
- [Laptop installation](installation-laptop.md): guía para añadir `zenbook`.
  Requiere generar hardware propio y registrar host en `flake.nix` antes de
  poder construir o mantenerlo con comandos como `nh os`.
