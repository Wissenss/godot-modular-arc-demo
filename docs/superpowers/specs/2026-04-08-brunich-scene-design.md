# Brunich Scene Design

## Goal

Reconstruir `scenes/tests/Brunich/Brunich_tests.tscn` como una arena coherente de combate usando recortes de `art/BetaTileSet_updown.png`, corregir la distorsion visual ligada al efecto glitch del MC sin perder su identidad, y convertir al enemigo en un rival de mayor aguante y agresividad.

## Scope

- Reemplazar el suelo procedural actual basado en `BetaTileSet_64.png` por un atlas reducido generado desde `BetaTileSet_updown.png`.
- Aplicar la direccion visual aprobada por el usuario: variante B, con suelo industrial hundido y una apertura superior para transicionar a otro cuarto.
- Mejorar la lectura del combate con mejor separacion entre fondo, MC y enemigo.
- Subir significativamente la vida del enemigo y darle comportamiento de persecucion, strafe, dodge y cadencia de disparo mayor.
- Verificar la escena con simulacion automatizada y corrida del juego en Godot.

## Visual Direction

- Base de piso: metal gris sobrio y panelado para no competir con el morado del MC.
- Profundidad: rebajes oscuros y paneles hundidos en las esquinas y zonas medias para que el cuarto no se vea plano.
- Acentos: detalles cian y dorados solo en puntos de lectura, no como relleno completo.
- Apertura superior: el borde norte debe quedar interrumpido en el centro para sugerir continuidad del nivel.
- Restriccion explicita: no usar tiles con texto o simbolos que parezcan palabras incrustadas en el suelo.

## Combat Readability

- El MC debe seguir leyendo como silueta principal sobre una base mas neutra.
- El fondo no debe deformarse al disparar ni al activar el glitch local del personaje.
- El enemigo debe sentirse mas peligroso por patron y presencia, no solo por numeritos.

## Technical Approach

- Generar un atlas nuevo desde `BetaTileSet_updown.png` con recortes concretos y reescalado a 32x32 para aumentar densidad visual sin cambiar el tamano total de la arena en pantalla.
- Extender `map_generator.gd` para construir ese `TileSet`, pintar la arena aprobada y exponer informacion de layout reutilizable por pruebas.
- Agregar colision de arena con salida superior abierta para sostener la fantasia espacial del cuarto.
- Sustituir el shader glitch dependiente de `SCREEN_TEXTURE` por una variante local sobre el overlay del MC para mantener el look sin tocar el fondo.
- Reescribir `enemy_regulated.gd` y `enemy_weapon.gd` para combinar posicionamiento tactico, rafagas y respuesta a proyectiles entrantes.

## Verification

- Prueba automatizada de escena para validar atlas nuevo, apertura superior, vida/cadencia del enemigo y respuesta de dodge.
- Corrida de Godot con la escena `Brunich_tests.tscn`.
- Simulacion de combate y capturas de evidencia cuando sea posible.
