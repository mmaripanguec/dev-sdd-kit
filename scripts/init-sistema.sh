#!/usr/bin/env bash
# init-sistema.sh - alias de compatibilidad; el nombre oficial es init-system.sh
exec "$(dirname "$0")/init-system.sh" "$@"
