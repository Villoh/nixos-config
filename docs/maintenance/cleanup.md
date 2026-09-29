# Limpieza de generaciones y espacio

Nix guarda en `/nix/store` cada derivación necesaria para perfiles y
configuraciones activas. Garbage collection borra solo rutas que ya no son
alcanzables desde perfiles o raíces del GC; no borra dependencias activas. Las
generaciones antiguas se mantienen como raíces para rollback, así que primero
hay que retirarlas de perfiles y luego recolectar store.

En este host, systemd-boot mantiene hasta cinco entradas. `nh clean all` limpia
perfiles de sistema y usuario, recolecta store y también revisa raíces de GC.
Por defecto puede retirar raíces de resultados de builds y de direnv. Lee
preview antes de ejecutar.

## Revisar antes de limpiar

Comprueba generaciones que quieres conservar:

```bash
nh os info
nix profile list
```

El primer comando lista generaciones del sistema. El segundo muestra paquetes
de perfil del usuario actual; no es equivalente a lista de generaciones
NixOS. Arranca sistema y prueba cambios pendientes antes de retirar
configuraciones antiguas.

## Limpieza recomendada

Primero previsualiza limpieza de todos los perfiles conservando al menos cinco
generaciones y todas las generaciones/raíces de los últimos 30 días:

```bash
nh clean all --keep 5 --keep-since 30d --dry
```

Revisa qué perfiles, generaciones y raíces propone borrar. Si listado conserva
rollback necesario, detente o ajusta retención. Para realizar la limpieza,
ejecuta comando de nuevo sin `--dry`:

```bash
nh clean all --keep 5 --keep-since 30d
```

`--keep` es mínimo por cantidad y `--keep-since` conserva por antigüedad;
pueden quedar más de cinco generaciones. Valores son retención, no objetivo de
borrar todo lo anterior. Mantén varias generaciones y evita limpiar mientras
estés diagnosticando fallo.

## Raíces temporales y direnv

`nh clean all` también elimina raíces indirectas obsoletas. Esto puede retirar
symlinks `result` de builds y raíces de proyectos direnv, por lo que store
puede ser recolectado si no queda ninguna otra referencia. Para conservar
raíces direnv:

```bash
nh clean all --keep 5 --keep-since 30d --no-direnv --dry
```

`--no-gcroots` desactiva limpieza de todas las raíces GC. Usa esa opción si
quieres recolectar generaciones y store sin tocar raíces temporales. Consulta
`nh clean all --help` para flags disponibles y dry-run antes de cambios.

## Optimizar store

`--optimise` deduplica archivos idénticos en store para reducir uso de disco.
No elimina versiones ni generaciones adicionales; es paso separado de la
recolección y puede tardar. Comprueba primero el plan de limpieza, luego puedes
incluir optimización:

```bash
nh clean all --keep 5 --keep-since 30d --optimise --dry
nh clean all --keep 5 --keep-since 30d --optimise
```

No uses `--delete-current` como limpieza rutinaria: permite retirar generación
seleccionada y puede dejar enlace del perfil colgando.

## Flatpak

Flatpak mantiene apps y runtimes fuera de Nix store. Actualízalos por separado:

```bash
flatpak update
```

Para retirar runtimes sin usar, revisa lista y deja que Flatpak confirme
eliminaciones:

```bash
flatpak list --runtime
flatpak uninstall --unused
```

No hay rollback NixOS para eliminación Flatpak; app o runtime pueden tener que
descargarse de nuevo.
