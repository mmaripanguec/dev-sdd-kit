---
name: clarify
description: Resuelve las ambigüedades de un requerimiento o spec con preguntas estructuradas (máx. 5) y registra las respuestas en la sección Clarificaciones de la spec. Usar entre el triage F0 y F1, cuando pidan "clarificar el requerimiento", o cuando una spec tenga marcadores [NECESITA CLARIFICACIÓN].
argument-hint: "<ruta-de-la-spec | descripción del requerimiento>"
allowed-tools: Read Glob Grep Edit
---

Clarifica: $ARGUMENTS

## Paso 1 — Escaneo de ambigüedad
Lee el requerimiento (o la spec y sus marcadores `[NECESITA CLARIFICACIÓN]`)
junto con el contexto de la fábrica (repos.yaml, packs vigentes, as-is,
knowledge/reglas-negocio.md). Evalúa cobertura por categoría — Clara /
Parcial / Ausente:
alcance y fuera de alcance · actores y permisos · flujo principal y
alternativos · datos y entidades · reglas de negocio · dependencias
externas · NFRs (volumen, latencia, disponibilidad) · seguridad/privacidad/
regulatorio · casos límite · criterios de éxito medibles.

## Paso 2 — Preguntas (máximo 5)
Solo pregunta lo que cumpla LAS TRES: (a) categoría Parcial/Ausente,
(b) la respuesta cambia alcance, diseño o certificación, (c) no hay default
razonable en el contexto cargado. Prioridad: alcance > seguridad/privacidad >
UX > detalle técnico. Formato por pregunta: enunciado concreto + tabla de
opciones (A, B, C… y "Otra") con la implicación de cada opción en una línea.
Presenta las preguntas de una en una o en bloque según prefiera el usuario;
lo demás NO se pregunta: se asume el default y se anota como supuesto.

## Paso 3 — Registrar
Con las respuestas:
1. Añade/actualiza en la spec la sección `## Clarificaciones` →
   `### Sesión <fecha de hoy>` con formato `- P: <pregunta> → R: <respuesta>
   (decide: <quién>)`.
2. Integra cada respuesta en la sección de la spec que corresponda
   (historias, análisis, fuera de alcance…) y elimina su marcador
   `[NECESITA CLARIFICACIÓN]`.
3. Ambigüedades detectadas pero no preguntadas (excedían el máximo o tenían
   default): al bloque Supuestos del § Análisis, o como marcador si bloquean
   (máximo 3 marcadores vivos en la spec).

Si aún no existe spec (se clarifica un requerimiento previo a /spec-create),
entrega el resumen de decisiones para que /spec-create lo incorpore desde F1.
No modifiques nada fuera de la spec indicada.
