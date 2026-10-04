# Programa 1: trayectorias T, S y D en Universal Robots

Solucion minima de la actividad **Programa 1**. El TCP de un UR5 simulado recorre
las letras T, S y D y muestra un popup bloqueante antes de cada letra. Este
repositorio no implementa los programas 2 ni 3.

## Entorno comprobado

- Contenedor: `universalrobots/ursim_e-series`, nombre `ursim`.
- Robot simulado: `UR5`.
- PolyScope/URControl: `5.26.1` (e-Series).
- Montaje: `./programa` en `/ursim/programs` con escritura habilitada.
- Instalacion activa: `programa/default.installation`, recreada y guardada por
  PolyScope 5.26.1 al iniciar (el archivo provisional anterior no se cargo).
- TCP activo: `p[0, 0, 0, 0, 0, 0]`; carga util: 0 kg.

Las poses de [programa1_tsd.script](programa/programa1_tsd.script) se eligieron
despues de comprobar ese modelo e instalacion. Las letras ocupan un rectangulo
aproximado de 43 cm de ancho por 18 cm de alto en el plano vertical
`y=-0.450 m`. Los traslados se hacen separados 5 cm del plano (`y=-0.400 m`) y
los trazos usan una velocidad baja de `0.08 m/s`.

## Archivos

- `programa/programa1_tsd.script`: unico programa de robot; contiene los tres
  popups y las tres trayectorias.
- `scripts/enviar_programa1.sh`: comprueba UR5/5.26 y envia el URScript por la
  interfaz secundaria del controlador.
- `scripts/verificar_programa1.sh`: diferencia un envio exitoso de una ejecucion
  que realmente alcanzo el final mediante `output_int_register_0` por RTDE.
- `scripts/leer_registro_rtde.py`: lector minimo RTDE usado por el verificador;
  no requiere paquetes de Python externos.
- `programa/default.installation` y `programa/default.variables`: instalacion
  que ya usa el URSim montado.

## Ejecutar

1. Abra PolyScope en <http://localhost:6080/vnc.html>.
2. En el menu superior derecho abra **Settings > System > Remote Control** y
   active **Enable**. Cierre Settings y cambie el selector **Local** de la barra
   superior: abra el **Profile menu** y seleccione **Remote Control**. Esta
   accion es necesaria: en modo local el controlador acepta la conexion TCP,
   pero descarta el URScript externo. Es el procedimiento indicado por el
   [manual oficial de PolyScope 5.26](https://www.universal-robots.com/manuals/EN/HTML/SW5_26/Content/prod-usr-man/software/PolyScope/content/hamburger_menu_g5/System_remote_en.htm).
3. En la esquina inferior izquierda, pulse **Power off** (o el indicador de
   estado), luego **ON** y finalmente **START**. El estado debe quedar en verde.
4. Desde la raiz del repositorio ejecute:

   ```bash
   chmod +x scripts/*.sh
   ./scripts/enviar_programa1.sh
   ```

5. La terminal indicara `ENVIADO`. Eso solo significa que URControl recibio el
   codigo. En PolyScope aparecera **Programa 1 - Letra T**: pulse **Continue**
   (es la confirmacion del popup). Haga lo mismo en los popups de **S** y **D**.
   Cada popup es bloqueante; la letra correspondiente no comienza hasta pulsar
   **Continue**.
6. Cuando termine el movimiento de la D, compruebe la finalizacion:

   ```bash
   ./scripts/verificar_programa1.sh
   ```

   El resultado esperado es `TERMINADO CORRECTAMENTE`. Si dice `ENVIADO, PERO
   NO TERMINADO`, mire PolyScope: puede quedar un popup pendiente o una alerta
   de movimiento.

No es necesario construir nodos de movimiento en PolyScope ni cargar un
archivo `.urp`: el script montado se envia directamente a URControl. Para
detenerlo use **Stop** en PolyScope. Para volver a ejecutarlo, repita los pasos
4 a 6.

## Que observar

- Antes de cada letra aparece exactamente un popup bloqueante con su nombre.
- Los movimientos sobre `y=-0.450 m` forman la letra; los cambios de trazo se
  realizan fuera del plano, en `y=-0.400 m`.
- El registro RTDE `output_int_register_0` vale `0` al iniciar, `10` tras T,
  `20` tras S, `30` tras D y `100` solo al finalizar correctamente.

Esta solucion solo se ha preparado para simulacion. Antes de usarla en un robot
fisico hay que revisar TCP, carga, espacio de trabajo, colisiones y poses con el
procedimiento de seguridad del laboratorio.
