# Brunich 2.5D Beta3 Design

## Goal

Migrar el cuarto principal de Brunich desde un top-down plano a una presentacion `2.5D / isometrico falso` usando los tiles `Beta3`, manteniendo intacta la logica de gameplay 2D para no romper movimiento, dash, apuntado, proyectiles ni enemigos.

## Decision

- No se movera el proyecto a `3D real`.
- No se aplicara una proyeccion isometrica matematica completa al gameplay.
- Se construira una ilusion de profundidad con capas visuales, muros altos, piezas de borde, props y composicion usando `Beta3`.

## Why This Direction

- El combate actual depende por completo de `Vector2`, `global_position`, `Polygon2D`, `CollisionPolygon2D` y armas 2D.
- Reescribir eso en 3D real costaria demasiado y retrasaria el proyecto.
- Los `Beta3` ya incluyen pisos, muros, esquinas, puertas, terminales y piezas hero suficientes para vender una lectura mas profunda sin tocar la base del combate.

## Room Presentation

- El cuarto base crecerá respecto al top-down actual para dar aire a perspectiva y capas.
- La zona jugable seguirá siendo un plano 2D rectangular.
- Encima de ese plano se dibujará un mundo `2.5D`:
  - piso modular con piezas `Beta3`
  - muros traseros y laterales con volumen
  - esquinas externas e internas
  - foreground y background controlados
  - props hero colocados para ritmo y profundidad

## Tile Strategy

- `Beta3` se usará de forma manual, no automática por terrain-set de Godot.
- Se preparará una selección de piezas útiles:
  - piso base
  - piso acentuado
  - piso dañado
  - muro recto
  - esquina externa
  - esquina interna
  - puerta / acceso
  - props de soporte
- El autotiling será manual en código: según vecinos lógicos del layout se elegirá la pieza visual correcta.

## Gameplay Constraints

- El MC, enemigos, rayos y proyectiles seguirán calculándose en 2D.
- No se cambiará el input base ni el sistema de dash.
- Los ataques solo se adaptarán visualmente para que lean bien dentro del cuarto nuevo.
- La cámara se abrirá y recentrará para aprovechar el cuarto grande sin perder claridad de combate.

## Implementation Slices

1. Selección de piezas `Beta3` y capas visuales nuevas.
2. Nuevo generador de cuarto 2.5D con profundidad falsa y autotiling manual.
3. Ajuste de tamaño de cuarto, spawn, cámara y composición.
4. Compatibilidad visual del MC y ataques dentro del nuevo espacio.
5. Verificación con smoke tests y capturas.

## Success Criteria

- El cuarto ya no se siente plano ni basado en oscuridad artificial.
- Los `Beta3` dominan la lectura visual del cuarto.
- La profundidad se percibe por muros, capas, escala y composición.
- El combate sigue funcionando como antes, sin reescritura 3D.
- El sistema queda lo bastante modular para repetir el enfoque en futuros biomas.
