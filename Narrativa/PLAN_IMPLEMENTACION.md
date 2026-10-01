# Plan de implementación del 2D

Sigue a [Organización](PLAN_ORGANIZACION.md), que queda como registro de lo ya
hecho. Aquí van las tandas que siguen, en orden. Cada tanda es una rama corta,
una PR y una prueba de Bruno antes de empezar la siguiente.

## Cómo se trabaja cada tanda

Esto corrige lo que salió mal antes: ramas `codex/…`, un worktree colgado de
otro proyecto que nadie podía cambiar, una tanda que se quedó sin tokens a
medias y commits que mezclaban limpieza, guardado y arte.

1. Antes de editar: `git status --short`, `git switch master`, `git pull`, y
   `git switch -c <area>/<cambio>` (por ejemplo `mapas/sala-unica`).
   Trabaja en esta carpeta, nunca en un worktree dentro de otro proyecto.
2. Primero la prueba que reproduce el problema y su resultado antes del cambio.
   Después el cambio más pequeño que lo arregla.
3. Commit en cuanto un paso funciona, con su prueba pasando, y `git push -u
   origin HEAD`. Si la sesión se corta, lo hecho ya está en el remoto y el
   siguiente sabe dónde seguir.
4. Un commit = un cambio que se nota jugando. Docs y pruebas del cambio van
   dentro de ese commit, no aparte. Staging por archivo, nunca `git add .`.
5. Al cerrar: `tools/run_suite.ps1` en 4.7.2 completo, y en la PR el número
   exacto (por ejemplo 25 de 25, código 0, sin ERROR en stderr).
6. En este plan sólo se cambia el estado de la tanda: hecho, evidencia y
   pendiente. Sin relato de intentos ni informes de sesión.
7. Si algo no está claro (diseño, historia, qué borrar) se pregunta a Bruno
   antes de implementarlo. Nada de carpetas `sin usar/` ni archivos `_old`:
   lo retirado vive en el historial de Git.

## Tanda 1 · Bruno prueba la progresión

Sin código nuevo. Bruno juega una run completa, una muerte y el regreso al hub,
y revisa contadores, desbloqueo del hackeo y final. Lo que encuentre se anota
aquí como tanda 1b antes de seguir.

Hecho cuando: Bruno confirma o deja la lista de fallos.

## Tanda 2 · Una sola definición de sala

Problema: la sala normal mide 40x20 tiles y la segunda de cada bioma 200x100
(megacore en `map_generator.gd`), 25 veces más celdas. Pintado, decoración,
spawns, cámara, límites y luces están repartidos entre `map_generator.gd`,
`room_decor.gd` y `brunich_tests.gd`.

1. Medir primero, con la misma semilla y en caliente: tiempo de entrada a la
   sala y cuadros por segundo en una sala de 40x20 y otra de 200x100. Anotar
   las dos cifras aquí.
2. Un recurso o diccionario de sala (tamaño, layout, spawns, puerta, límites,
   cámara) que lean los tres dueños, en vez de que cada uno calcule el suyo.
3. Bruno decide con esas cifras si la sala grande se queda, se reduce o se
   carga por partes. No se elige por él.

Prueba: `tools/verify_visual.gd` y `brunich_progression_smoke.gd` siguen
pasando; una prueba nueva sólo si comprueba la definición compartida.

## Tanda 3 · Spawn, puerta y reentrada

Antes de partir el orquestador (`brunich_tests.gd`): una prueba que recorre
cada layout y comprueba que el jugador aparece fuera de paredes, que la puerta
es alcanzable, que los proyectiles mueren en el límite y que al volver a entrar
no quedan enemigos ni decoración duplicados. Sólo con esa red se extraen
responsabilidades del orquestador, una por commit.

## Tanda 4 · Jerarquía visual en un mapa

Un único mapa. Los props luminosos y las capas oscuras tapan los tiles.
Captura antes y después del mismo encuadre jugable y un clip corto en
movimiento; la rejilla sigue en 32 px (la biblia habla de 64, no se migra).
Bruno aprueba ese mapa antes de tocar los demás.

## Tanda 5 · Menú y hub con foco

Pasar menú y hub de hit-test manual a `Control` con foco, para que funcionen
con teclado, mando y ratón. `tools/verify_hub_mouse.gd` y
`verify_progression_ui.gd` deben seguir pasando; añadir la navegación con
teclado a esas pruebas, no una batería nueva.

## Tanda 6 · Poderes, enemigos y dificultad

Sólo después de las anteriores, y una cosa por tanda. El robo (E, rango 76) y
los perfiles de arma ya existen: lo nuevo se apoya en ellos.

## Fuera de este plan

Integrar este juego en el minijuego de carga de IA Rogue. Cuando toque, tendrá
que usar tiempo local en vez de `Engine.time_scale`, que afectaría a todo el
juego 3D. Se planifica en el repo de IA Rogue, no aquí.
