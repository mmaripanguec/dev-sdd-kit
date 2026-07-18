# Perfil de dominio: banca
> Aplica a los repos cuyo registro (`repos.yaml`) declara `domain: banking`.
> Complementa las reglas base; no las reemplaza.
> Base: BIAN Service Landscape · ISO 20022 · OWASP ASVS

- Landscape de dominios: las capacidades se asignan a service domains BIAN
  (p.ej. `payment-order`, `customer-offer`); un dominio = un módulo con API
  y datos propios, sin solapamiento.
- Vocabulario de payloads alineado a ISO 20022 cuando el dominio es de pagos.
- Rutas críticas del dominio = toda ruta de DINERO (transferencias, pagos,
  abonos) y de AUTENTICACIÓN: cobertura de tests del 100% e idempotencia
  obligatoria (idempotency-key) en operaciones de dinero.
- Threat modeling (STRIDE) obligatorio para features que tocan dinero,
  además de los disparadores base (auth, datos personales).
- Datos transaccionales y personales: cifrado en tránsito y en reposo;
  requisitos regulatorios financieros identificados en la spec (sección
  Análisis) como no-negociables.
- Los montos se manejan con tipos exactos (decimal/entero de centavos),
  nunca punto flotante; toda operación registra moneda explícita.
