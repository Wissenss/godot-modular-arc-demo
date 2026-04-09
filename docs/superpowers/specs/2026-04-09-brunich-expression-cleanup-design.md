# Brunich Expression Rotation And Cleanup Design

## Goal

Reducir el volumen del proyecto activo de Brunich para que solo conserve las expresiones, escenas y archivos realmente aprobados o usados por el flujo jugable actual, mientras se agrega una rotacion automatica de expresiones cada 20 segundos sin romper las expresiones especiales del gameplay.

## Scope

- Mantener `res://scenes/tests/Brunich/Brunich_tests.tscn` como escena principal jugable.
- Agregar rotacion automatica de expresiones del MC cada `20.0` segundos.
- Separar expresiones "normales" de expresiones especiales ligadas a eventos.
- Reducir el catalogo activo de expresiones a una allowlist explicita.
- Mover expresiones descartadas, previews sobrantes, HTML de ideas y escenas/script legado adicionales a `sin usar/`.
- Duplicar la scene principal de Brunich para `Pato`, `Rodolfo`, `Charls` y `Wissens` para que cada compañero tenga una base propia.

## Assumptions

- Hasta que el usuario indique una lista distinta, "expresiones aprobadas" significa las expresiones que hoy ya participan del flujo jugable o de depuracion del MC.
- Para este primer pase, la allowlist inicial sera:
  - Normales activas: `angry`
  - Especiales por evento: `happy`, `scan`, `glitch`, `glitch_angry_a`, `glitch_angry_b`, `glitch_angry_c`
- La rotacion automatica no debe usar expresiones especiales. Si la allowlist normal queda en una sola expresion, la estructura de rotacion quedara lista pero el personaje permanecera en esa expresion hasta que el usuario apruebe mas caras normales.
- El material archivado debe seguir siendo recuperable, por lo que se movera a `sin usar/` preservando estructura relativa siempre que tenga sentido.

## Design

### 1. Catalogo de expresiones

- El catalogo activo ya no dependera de "todo lo que exista en la carpeta".
- `test_character_shaders.gd` trabajara con una allowlist explicita para:
  - expresiones normales rotables
  - expresiones especiales de override
- Al cargar `mc_face_expressions.json`, el script filtrara el diccionario a esa allowlist antes de usarlo.
- Los assets de preview o referencia fuera de la allowlist se moveran a `sin usar/` para que la carpeta visible deje de crecer sin criterio.

### 2. Rotacion automatica cada 20 segundos

- Se agregara un temporizador interno al MC para cambiar a la siguiente expresion normal cada `20.0` segundos.
- La rotacion no interrumpira overrides temporales como:
  - `happy` al eliminar enemigo
  - `scan` al robar ataque
  - `glitch` durante dano
- Cuando termine un override, el personaje volvera a la expresion vigente dentro del ciclo automatico, no necesariamente a `angry` de forma fija.

### 3. Limpieza de carpeta activa

- El criterio de limpieza sera conservar solo lo necesario para:
  - la escena principal jugable de Brunich
  - los tests y probes activos
  - las expresiones aprobadas
  - las nuevas copias base para companeros
- Todo lo demas que hoy solo suma ruido visual o de lectura se movera a `sin usar/`, incluyendo:
  - previews de expresiones descartadas
  - HTML de ideas como `Narrativa/preview/rogue_motion_gallery.html`
  - escenas de prueba antiguas o variantes no activas adicionales
- No se moveran archivos alcanzables desde la escena principal actual ni desde los tests activos.

### 4. Copias por companero

- Se duplicara la base actual de Brunich para crear escenas separadas para:
  - `Pato`
  - `Rodolfo`
  - `Charls`
  - `Wissens`
- Cada copia apuntara a su propio script para que los cambios futuros de cada persona no pisen la implementacion de Brunich.
- La version de Brunich seguira siendo la referencia canonica y `run/main_scene`.

## Technical Approach

- Escribir primero una prueba que verifique:
  - existencia del intervalo de rotacion
  - no interferencia con overrides especiales
  - filtrado del catalogo a la allowlist
  - carga correcta de las nuevas scenes clonadas
- Extender `scenes/tests/Brunich/test_character_shaders.gd` con:
  - constante del intervalo
  - listas explicitas de expresiones normales y especiales
  - contador o reloj de rotacion
  - helper para avanzar expresion activa
- Actualizar `scripts/tests/brunich_scene_smoke.gd` para reflejar el nuevo comportamiento esperado.
- Mover archivos fisicos a `sin usar/` solo despues de fijar la allowlist y revisar referencias activas.

## Error Handling

- Si una expresion allowlisted falta en `mc_face_expressions.json`, el sistema debe conservar `angry` como fallback seguro.
- Si una scene clonada pierde una referencia, la verificacion debe fallar antes de dar por terminada la limpieza.
- Si un archivo candidato a mover sigue referenciado por una scene o test activos, se queda en la ruta activa y se documenta como dependencia viva.

## Verification

- Ejecutar la smoke test de Brunich en headless.
- Verificar por codigo que la allowlist filtrada coincide con el catalogo activo real.
- Confirmar que las scenes de `Pato`, `Rodolfo`, `Charls` y `Wissens` instancian sin errores.
- Confirmar que el proyecto sigue abriendo con `Brunich_tests.tscn` como escena principal.
