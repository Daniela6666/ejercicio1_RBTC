#!/usr/bin/env python3
"""Lee output_int_register_0 por RTDE usando solo la biblioteca estandar."""

import socket
import struct


RTDE_REQUEST_PROTOCOL_VERSION = 86
RTDE_CONTROL_PACKAGE_SETUP_OUTPUTS = 79
RTDE_CONTROL_PACKAGE_START = 83
RTDE_DATA_PACKAGE = 85


def recibir_exacto(conexion, cantidad):
    datos = b""
    while len(datos) < cantidad:
        bloque = conexion.recv(cantidad - len(datos))
        if not bloque:
            raise RuntimeError("URControl cerro la conexion RTDE")
        datos += bloque
    return datos


def enviar(conexion, tipo, contenido=b""):
    conexion.sendall(struct.pack(">HB", len(contenido) + 3, tipo) + contenido)


def recibir(conexion):
    tamano, tipo = struct.unpack(">HB", recibir_exacto(conexion, 3))
    return tipo, recibir_exacto(conexion, tamano - 3)


with socket.create_connection(("127.0.0.1", 30004), timeout=5) as rtde:
    enviar(rtde, RTDE_REQUEST_PROTOCOL_VERSION, struct.pack(">H", 2))
    tipo, respuesta = recibir(rtde)
    if tipo != RTDE_REQUEST_PROTOCOL_VERSION or respuesta != b"\x01":
        raise RuntimeError("URControl rechazo RTDE v2")

    contenido = struct.pack(">d", 10.0) + b"output_int_register_0"
    enviar(rtde, RTDE_CONTROL_PACKAGE_SETUP_OUTPUTS, contenido)
    tipo, respuesta = recibir(rtde)
    if tipo != RTDE_CONTROL_PACKAGE_SETUP_OUTPUTS or not respuesta:
        raise RuntimeError("No se pudo crear la receta RTDE")
    receta = respuesta[0]
    if respuesta[1:] != b"INT32":
        raise RuntimeError("Tipo RTDE inesperado: " + respuesta[1:].decode("ascii"))

    enviar(rtde, RTDE_CONTROL_PACKAGE_START)
    tipo, respuesta = recibir(rtde)
    if tipo != RTDE_CONTROL_PACKAGE_START or respuesta != b"\x01":
        raise RuntimeError("URControl no inicio el envio RTDE")

    while True:
        tipo, respuesta = recibir(rtde)
        if tipo == RTDE_DATA_PACKAGE and respuesta[0] == receta:
            print(struct.unpack(">i", respuesta[1:5])[0])
            break
