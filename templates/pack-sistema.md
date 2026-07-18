---
name: {{PREFIJO}}-sistema
description: >-
  EMPIEZA POR AQUÍ para cualquier cosa de {{SISTEMA}}. Modelo mental, mapa
  de los repos y las uniones entre ellos (lo que no vive en ningún repo).
  Úsalo antes que cualquier pack {{PREFIJO}}-<repo>, y siempre que se pida
  arquitectura, diseño, análisis de impacto o cambios que crucen componentes.
version: 1.0.0
generado_desde:
  {{REPO_1}}: {{SELLO_1}}
verificado: {{FECHA}}
---

# {{SISTEMA}} — el sistema

**Este pack contiene lo que NO vive en ningún repo: las uniones.** Los packs
por repo tienen el detalle; aquí está lo que solo se ve mirando dos o más a
la vez. Léelo primero.

## Los repos

| Pack | Repo | Qué es |
|---|---|---|
| `{{PREFIJO}}-<repo>` | `<repo>` | <una frase: qué es de verdad> |

## ⭐ El modelo mental
> **<LA afirmación central del sistema: la que cambia cómo se entiende todo
> lo demás.>**

<Desarrollo con la cadena de evidencia completa (`repo/archivo:línea` en
cada eslabón). Incluir "los errores que comete quien no lo sabe".>

## ⭐ <Uniones y hallazgos cross-repo>
<Cómo se comunican los repos DE VERDAD (no el diagrama teórico): fan-out,
contratos, colas, sesión compartida... con evidencia en ambos extremos.>

## Trampas — no caigas en estas
| Afirmación falsa | Realidad |
|---|---|
| <lo que este pack o el equipo creyó antes y era falso> | <realidad + evidencia> |

## Cómo trabajar
**Orden**: este pack → el pack del repo que tocas → grafo/as-is → leer código.

| Necesitas | Pack |
|---|---|
| <tema> | `{{PREFIJO}}-<repo>` |

### Verificación mecánica — no dependas de mi criterio
```bash
scripts/afirmaciones.sh {{SISTEMA}}   # ¿alguna afirmación ya es falsa?
scripts/frescura.sh comprobar         # ¿caducó algún pack?
```
**Regla**: toda corrección comprobable mecánicamente acaba en
`scripts/afirmaciones.d/{{SISTEMA}}.sh`. Si no, vuelve.

## Qué NO sé
- <límites explícitos del conocimiento del sistema; inferencias marcadas>

**Este pack no demuestra su completitud.** Si conoces el sistema y algo te
chirría, probablemente el pack esté mal, no tú.
