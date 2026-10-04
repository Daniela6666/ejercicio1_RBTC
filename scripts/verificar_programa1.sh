#!/usr/bin/env bash
set -euo pipefail

contenedor="${URSIM_CONTAINER:-ursim}"
raiz="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
registro="$(docker exec -i "$contenedor" python3 - < "$raiz/scripts/leer_registro_rtde.py")"

case "$registro" in
  100)
    echo "TERMINADO CORRECTAMENTE: T, S y D alcanzaron el final (registro RTDE=100)."
    ;;
  0)
    echo "ENVIADO, PERO NO TERMINADO: esperando el popup o la trayectoria T."
    exit 2
    ;;
  10)
    echo "ENVIADO, PERO NO TERMINADO: T termino; esperando S."
    exit 2
    ;;
  20)
    echo "ENVIADO, PERO NO TERMINADO: T y S terminaron; esperando D."
    exit 2
    ;;
  30)
    echo "ENVIADO, PERO NO TERMINADO: D termino, pero falta el marcador final."
    exit 2
    ;;
  *)
    echo "ERROR: valor inesperado en output_int_register_0: $registro" >&2
    exit 1
    ;;
esac
