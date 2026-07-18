# Postmortem: <título> (INC-NNNN)
> Formato: Google SRE — postmortem sin culpables. Las personas no fallan;
> los sistemas y procesos permiten el fallo.

- **Fecha / Duración / Severidad:**
- **Servicios afectados / Impacto a usuarios:** (números, no adjetivos)
- **Detección:** cómo nos enteramos (alerta, cliente, azar) y cuánto tardó.
- **MTTR:** __ (registrar también en knowledge/uso.md)

## Cronología (timestamps)
- HH:MM — primer síntoma …
- HH:MM — mitigación aplicada …

## Causa raíz (5 porqués)
1. ¿Por qué falló? …
2. ¿Por qué …? …
(distinguir causa raíz de factores contribuyentes)

## Qué funcionó / Qué no funcionó
## Acciones correctivas
| Acción | Tipo (prevenir/detectar/mitigar) | Dueño | Fecha | Test/regla generada |
|---|---|---|---|---|

## Cierre del ciclo
Qué spec, regla (.claude/rules/ o knowledge/reglas-negocio.md) o criterio de
aceptación futuro se actualiza con lo aprendido.
