# Seguridad
> Base: NIST SP 800-218 (SSDF) y 800-218A (GenAI) · Microsoft SDL · OWASP Top 10 / ASVS

## Producir software bien asegurado (SSDF grupo PW)
- Validar TODA entrada externa en el borde; sanitizar salidas (XSS, inyección SQL/NoSQL/OS).
- Secretos solo vía gestor de secretos/variables de entorno; PROHIBIDO en código,
  logs, specs o commits. `.env` y llaves están vetados a los agentes (settings.json).
- Autenticación y autorización en cada endpoint; denegar por defecto.
- Cifrado en tránsito (TLS) y en reposo para datos personales/financieros.
- Dependencias: solo versiones fijadas; correr análisis de vulnerabilidades (SCA)
  antes de certificar; generar SBOM en el paso a producción (SSDF grupo PS).

## Ciclo (Microsoft SDL)
- Threat modeling (STRIDE) obligatorio en fase de Diseño para features que tocan
  auth, dinero o datos personales; el resultado va al ADR.
- Análisis estático (SAST) en CI; hallazgos critical/high bloquean el merge.

## Respuesta (SSDF grupo RV)
- Toda vulnerabilidad detectada en operación genera incidente + postmortem +
  test de regresión + revisión de la causa raíz en el proceso.

## Agentes de IA (SSDF 800-218A / NIST AI RMF)
- Los agentes no reciben credenciales de producción; gates humanos respaldados
  por permisos, no solo por instrucciones.
- Código generado por IA pasa por los mismos controles que el humano: revisión,
  SAST, tests. La autoría no exime del control.
