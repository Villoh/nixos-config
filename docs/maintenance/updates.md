# Actualizar sistema y aplicaciones

Los paquetes declarados en NixOS o Home Manager cambian cuando se actualizan
los inputs del flake y se reconstruye la configuración. No actualices esos
paquetes manualmente: cambia su versión en la configuración cuando sea
necesario.

## Actualizar inputs del flake

Desde la raíz del repositorio, revisa primero qué inputs cambiarán:

```bash
cd /home/mikel/src/nixos-config
git status --short
nix flake update
git diff --stat
git diff -- flake.lock
```

`nix flake update` actualiza todos los inputs y guarda versiones nuevas en
`flake.lock`. Para actualizar solo `nixpkgs`:

```bash
nix flake lock --update-input nixpkgs
```

Después valida y activa temporalmente. Consulta [nh](nh.md) para equivalentes
con su interfaz:

```bash
nix flake check
sudo nixos-rebuild test --flake .#desktop
```

Verifica sesión gráfica, red, audio, Bluetooth y portales Wayland. Solo tras
probar el resultado, aplícalo como generación predeterminada:

```bash
sudo nixos-rebuild switch --flake .#desktop
```

No uses `switch` para saltarte validación o prueba. Revisa el diff antes de
aplicar cambios; no descartes cambios locales que no sean tuyos.

## Perfiles manuales de Nix

`nix profile` instala paquetes fuera de NixOS y Home Manager. Úsalo solo para
apps que deliberadamente no estén declaradas en este repositorio. Primero mira
qué perfiles contienen:

```bash
nix profile list
```

Previsualiza actualización de paquetes del perfil actual antes de ejecutar:

```bash
nix profile upgrade --all --dry-run
nix profile upgrade --all
```

Instala manualmente solo si declararlo no es lo apropiado:

```bash
nix profile install nixpkgs#hello
```

Si `nix profile list` no muestra entradas, no hay apps instaladas por ese
perfil. La actualización del perfil no actualiza configuración del sistema.

## Flatpak

Flatpak se actualiza por separado del flake:

```bash
flatpak update
```

Consulta [Limpieza](cleanup.md) para retirar runtimes Flatpak sin usar.
