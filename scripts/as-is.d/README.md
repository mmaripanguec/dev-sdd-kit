# Extractores de rutas por repositorio

Si el extractor generico de `generate-as-is.sh` no captura las rutas de un repo
(framework raro, rutas en config, gRPC), se escribe aqui un extractor EXACTO:

- Nombre: `<nombre-del-repo>.sh` (ej. `homebanking-pwa-proxy.sh`), ejecutable.
- Contrato: recibe la ruta del repo como `$1`; imprime una ruta por linea
  con formato `/segmento[/...]`.
- Quien los escribe: la skill `/as-is-learn` (Claude Code analiza el codigo
  real y deja aqui el extractor con la evidencia citada en comentarios).
- Se commitean al workspace: son conocimiento del sistema.
