# Brunich 2.5D Beta3 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rehacer el cuarto principal de Brunich como una arena 2.5D con Beta3 manteniendo el gameplay 2D.

**Architecture:** El `TileMapLayer` actual seguirá siendo la base lógica del cuarto, pero la presentación visual pasará a construirse con capas manuales de piso, muros y props `Beta3`. La cámara y el spawn se ajustarán al nuevo tamaño del cuarto, mientras el MC y los ataques conservarán su lógica 2D actual.

**Tech Stack:** Godot 4.6, GDScript, TileMapLayer, Sprite2D, AtlasTexture, smoke tests headless.

---

### Task 1: Definir la verificación del nuevo cuarto 2.5D

**Files:**
- Create: `scripts/tests/brunich_beta3_room_smoke.gd`
- Modify: `scenes/tests/Brunich/map_generator.gd`

- [ ] Escribir una smoke que falle si el cuarto no monta capas visuales `iso_floor_root`, `iso_wall_back_root`, `iso_wall_front_root` y un tamaño mayor al cuarto base previo.
- [ ] Ejecutarla para confirmar fallo.
- [ ] Implementar la estructura mínima para que pase.
- [ ] Volver a correrla.

### Task 2: Seleccionar y montar piezas Beta3

**Files:**
- Modify: `scenes/tests/Brunich/map_generator.gd`
- Create: `art/_beta3_analysis/*`

- [ ] Crear el catálogo de piezas Beta3 útiles para piso, muro, esquina y puerta.
- [ ] Construir helpers para crear `AtlasTexture`/regiones desde los sheets Beta3.
- [ ] Dibujar piso y muros con capas dedicadas.
- [ ] Verificar que el cuarto ya usa Beta3 visualmente.

### Task 3: Implementar autotiling manual de profundidad

**Files:**
- Modify: `scenes/tests/Brunich/map_generator.gd`

- [ ] Modelar una grilla lógica de piso y una grilla lógica de muros.
- [ ] Elegir sprites según vecinos para bordes, esquinas y tramos rectos.
- [ ] Añadir piezas hero y foreground/background sin saturar.
- [ ] Mantener la salida superior y colisiones compatibles.

### Task 4: Adaptar cámara, tamaño y lectura del combate

**Files:**
- Modify: `scenes/tests/Brunich/brunich_tests.gd`
- Modify: `scenes/tests/Brunich/test_character_shaders.gd`
- Modify: `scenes/tests/Brunich/weapon_one_shader.gd`

- [ ] Aumentar el cuarto base a un tamaño intermedio más amplio.
- [ ] Reubicar spawn, límites de cámara y composición principal.
- [ ] Ajustar visualmente al MC y ataques para que no se pierdan contra el nuevo escenario.
- [ ] Confirmar que no se rompe input ni combate.

### Task 5: Verificación visual final

**Files:**
- Modify: `scripts/tests/brunich_render_probe.gd`
- Test: `scripts/tests/brunich_visual_stack_smoke.gd`
- Test: `scripts/tests/brunich_room_art_smoke.gd`
- Test: `scripts/tests/brunich_hud_values_smoke.gd`

- [ ] Correr las smokes críticas del cuarto.
- [ ] Generar capturas nuevas del cuarto.
- [ ] Revisar la lectura final y hacer un último ajuste fino si hace falta.
