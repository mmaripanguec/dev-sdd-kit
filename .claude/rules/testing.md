# Testing
> Base: pirámide de tests (Google Testing Blog) · TDD (Beck) · ISO/IEC 25010

- TDD para toda lógica de negocio: test que falla → commit del test → implementar
  → verde → refactor. NUNCA modificar el test para hacerlo pasar.
- Pirámide: mayoría unit (rápidos, aislados), integración para contratos entre
  módulos, E2E solo para flujos críticos de usuario.
- Cobertura mínima en código nuevo: 80% líneas / 100% en rutas de dinero y auth.
  La cobertura es piso, no meta: cada caso límite de la spec tiene su test.
- Tests deterministas: sin sleeps, sin dependencia de red externa, sin orden implícito.
- Datos de prueba sintéticos; PROHIBIDO usar datos reales de clientes en tests.
- Cada bug corregido añade primero el test que lo reproduce (regresión).
