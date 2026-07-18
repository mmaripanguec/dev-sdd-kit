#!/usr/bin/env bash
# afirmaciones.sh - Suite de aserciones de los packs de contexto.
# Convierte cada afirmacion comprobable de un pack en un test ejecutable.
#
# POR QUE EXISTE (leccion del proyecto de referencia br-arquitectura):
# frescura.sh solo detecta QUE algo cambio (sello); esto detecta QUE
# AFIRMACION se volvio falsa. Es la diferencia entre "el pack puede estar
# viejo" y "la linea 47 miente".
#
# LA REGLA (asi "aprenden" los packs de sus correcciones):
#   Toda correccion a un pack que sea comprobable mecanicamente TIENE que
#   acabar aqui como asercion. Si no, el error volvera.
#
# USO
#   scripts/afirmaciones.sh              # corre todas las suites
#   scripts/afirmaciones.sh <sistema>    # solo scripts/afirmaciones.d/<sistema>.sh
#   rc=1 si alguna afirmacion es falsa.
#
# Como se agrega una (dentro de scripts/afirmaciones.d/<sistema>.sh):
#   afirmar "<lo que el pack dice>" <esperado> "<comando que lo mide>"
# Compatible bash 3.2 (macOS).
set -uo pipefail
cd "$(dirname "$0")/.."
. scripts/repo-lib.sh

OK=0; FAIL=0
afirmar() {  # <descripcion> <esperado> <comando>
  _desc="$1"; _esperado="$2"; _cmd="$3"
  _real="$(eval "${_cmd}" 2>/dev/null | tr -d ' \n')"
  if [ "${_real}" = "${_esperado}" ]; then
    printf "  ok    %-64s = %s\n" "${_desc}" "${_real}"; OK=$((OK + 1))
  else
    printf "  FALSA %-64s esperado=%s real=%s\n" "${_desc}" "${_esperado}" "${_real}"
    FAIL=$((FAIL + 1))
  fi
}

SUITES=""
if [ -n "${1:-}" ]; then
  SUITES="scripts/afirmaciones.d/$1.sh"
  if [ ! -f "${SUITES}" ]; then
    echo "ERROR - no existe ${SUITES}. Suites disponibles:"
    ls scripts/afirmaciones.d/*.sh 2>/dev/null | sed 's/^/  /' || echo "  (ninguna)"
    exit 2
  fi
else
  SUITES=$(ls scripts/afirmaciones.d/*.sh 2>/dev/null || true)
fi

if [ -z "${SUITES}" ]; then
  echo "Sin suites en scripts/afirmaciones.d/ - nada que verificar."
  echo "(las siembran /repo-map y /system-map con las afirmaciones de cada pack)"
  exit 0
fi

for suite in ${SUITES}; do
  echo "== $(basename "${suite}" .sh) =="
  . "${suite}"
done

echo
echo "Afirmaciones: ${OK} ok, ${FAIL} falsas"
if [ "${FAIL}" -gt 0 ]; then
  echo "ATENCION - hay afirmaciones FALSAS: el pack correspondiente miente."
  echo "Corrige el pack y actualiza la asercion; nunca borres la asercion sin corregir."
  exit 1
fi
