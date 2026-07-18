# Estilo de código
> Base: Google Style Guides (google.github.io/styleguide) · Google eng-practices (revisión de código)

- Seguir la guía de estilo de Google del lenguaje del proyecto; el linter la codifica
  y es la autoridad final. Cero warnings para commitear.
- Funciones cortas con una responsabilidad; nombres descriptivos sin abreviaturas.
- Sin `any` / tipos dinámicos en código nuevo; tipado estricto activado.
- Comentarios explican el PORQUÉ, no el qué. Código muerto se borra, no se comenta.
- Cambios pequeños y autocontenidos: un commit = una intención (los CLs pequeños
  se revisan mejor y se revierten sin dolor).
- Manejo de errores explícito: nunca tragar excepciones; errores con contexto accionable.
