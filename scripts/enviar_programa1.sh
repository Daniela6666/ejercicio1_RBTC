#!/usr/bin/env bash
set -euo pipefail

contenedor="${URSIM_CONTAINER:-ursim}"
raiz="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
programa="$raiz/programa/programa1_tsd.script"

if ! docker inspect "$contenedor" >/dev/null 2>&1; then
  echo "ERROR: no existe o no es accesible el contenedor '$contenedor'." >&2
  exit 1
fi

modelo="$(docker exec "$contenedor" printenv ROBOT_MODEL)"
version="$(docker exec "$contenedor" printenv VERSION)"
if [[ "$modelo" != "UR5" || "$version" != 5.26.* ]]; then
  echo "ERROR: las poses se validaron para UR5/PolyScope 5.26; detectado $modelo/$version." >&2
  exit 1
fi

estado="$(docker exec "$contenedor" bash -lc '
  exec 3<>/dev/tcp/127.0.0.1/29999
  IFS= read -r _ <&3
  printf "robotmode\n" >&3
  IFS= read -r respuesta <&3
  printf "%s" "$respuesta"
')"
if [[ "$estado" != "Robotmode: RUNNING" ]]; then
  echo "ERROR: el robot no esta operativo ($estado). En PolyScope, pulse ON y luego START." >&2
  exit 1
fi

remoto="$(docker exec "$contenedor" bash -lc '
  exec 3<>/dev/tcp/127.0.0.1/29999
  IFS= read -r _ <&3
  printf "is in remote control\n" >&3
  IFS= read -r respuesta <&3
  printf "%s" "$respuesta"
')"
if [[ "$remoto" != "true" ]]; then
  echo "ERROR: PolyScope esta en modo local y no ejecutara URScript externo." >&2
  echo "Active Remote Control en Settings > System > Remote Control y seleccione Remote." >&2
  exit 1
fi

docker exec -i "$contenedor" python3 -c '
import socket
import sys
import time

programa = sys.stdin.buffer.read()
with socket.create_connection(("127.0.0.1", 30002), timeout=5) as cliente:
    cliente.sendall(programa)
    time.sleep(1)
' < "$programa"

echo "ENVIADO: programa1_tsd.script fue entregado al controlador."
echo "Esto confirma el envio, NO que las trayectorias hayan terminado."
echo "En PolyScope pulse Continue en los tres popups: T, S y D."
echo "Luego ejecute: ./scripts/verificar_programa1.sh"
