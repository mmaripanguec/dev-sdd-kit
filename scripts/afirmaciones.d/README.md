# Suites de aserciones por sistema

Una suite `<sistema>.sh` por sistema con packs de contexto. Las siembran
`/repo-map` y `/system-map` al generar cada pack, y las amplia toda
correccion posterior (regla: correccion comprobable => asercion).

Formato (se ejecutan con `source` desde `scripts/afirmaciones.sh`, que
provee `afirmar` y las funciones de `repo-lib.sh`):

```bash
# <sistema>.sh - afirmaciones de los packs <prefijo>-*
afirmar "el proxy expone N rutas en handler.go" 45 \
  "grep -c 'HandleFunc' repos/mi-proxy/internal/handlers/handler.go"
afirmar "el core NO conoce JWT" 0 \
  "grep -ril jwt repos/mi-core/src | wc -l"
```

- `<esperado>` se compara contra la salida del comando sin espacios.
- Usar SIEMPRE rutas `repos/<nombre>/` (funcionan tambien para snapshots
  enlazados) y comandos de solo lectura (grep/find/wc).
