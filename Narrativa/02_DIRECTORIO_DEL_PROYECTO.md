# Directorio del juego 2D

Las rutas siguientes son relativas al proyecto. `scenes/tests/Brunich/` contiene
el juego real; `scripts/tests/` contiene las pruebas. Los nombres son históricos,
no una razón para moverlos sin revisar referencias.

## Flujo activo

`project.godot` abre `scenes/tests/Brunich/main_menu.tscn`.
Un slot nuevo pasa por `intro_cinematic.tscn`; después entra a `rest_zone.tscn`.
Desde el hub comienza `Brunich_tests.tscn`; al morir o completar la run vuelve al hub.
El único autoload declarado es `SaveManager`.

## Código por área

| Área | Dueño y contrato | Prueba cercana |
|---|---|---|
| Menú y selección de slot | `scenes/tests/Brunich/main_menu.gd`; abre slot y escena | `scripts/tests/brunich_metagame_smoke.gd` mediante lanzador |
| Hub, Archivista y mejoras | `scenes/tests/Brunich/rest_zone.gd`; NPCs y compras | `scripts/tests/brunich_rest_zone_layout_smoke.gd` |
| Guardado | `scenes/tests/Brunich/save_manager.gd`; tres slots, esquema 2, recursos, mejoras, intentos y finales | metagame, `tools/verify_save_isolation.gd`, `tools/verify_run_progression.gd` |
| Introducción | `scenes/tests/Brunich/intro_cinematic.gd` | metagame mediante lanzador |
| Salas, enemigos y avance | `scenes/tests/Brunich/brunich_tests.gd`; orquestador activo, final tras tres/cuatro capas | `scripts/tests/brunich_progression_smoke.gd`, `tools/verify_run_progression.gd` |
| Pintado de mapa y límites | `scenes/tests/Brunich/map_generator.gd`; TileMapLayer, atlas, dimensiones | `tools/verify_visual.gd` |
| Decoración y profundidad | `scenes/tests/Brunich/room_decor.gd`; props por layout | `scripts/tests/brunich_room_decor_transparency_smoke.gd` |
| Luz y composición de sala | `brunich_tests.gd` y `scenes/tests/Brunich/visual_stack/brunich_visual_stack.gd` | `scripts/tests/brunich_visual_stack_smoke.gd` |
| Movimiento, dash, foco y cara | `scenes/tests/Brunich/test_character_shaders.gd`; jugador real | `scripts/tests/brunich_scene_smoke.gd`, `brunich_accelerated_thought_smoke.gd` |
| Arma del jugador | `scenes/tests/Brunich/weapon_one_shader.gd`; instala perfiles y aplica bonos | `scripts/tests/brunich_attack_balance_smoke.gd` |
| Robo | `test_character_shaders.gd` y `scenes/tests/Brunich/enemy_attack_pickup.gd`; E, rango 76, consume perfil | `scripts/tests/brunich_stolen_weapons_smoke.gd` |
| Enemigos comunes | `scenes/tests/Brunich/enemy_regulated.gd`; variantes por escenas y exports | `scripts/tests/brunich_enemy_polish_smoke.gd` |
| Núcleo enemigo | `scenes/tests/Brunich/enemy_ai_core.gd`; deriva de EnemyRegulated | `scripts/tests/brunich_enemy_ai_core_smoke.gd` |
| Haz enemigo y robado | `scenes/tests/Brunich/enemy_ai_beam.gd`, `enemy_ai_core_weapon.gd` | `scripts/tests/brunich_ai_core_beam_smoke.gd`, `brunich_stolen_ai_beam_smoke.gd` |
| Proyectiles | `scenes/tests/Brunich/projectile_one_shader.gd`, `enemy_projectile.gd` | pruebas de armas y balance |
| Efectos de combate | `scenes/tests/Brunich/combat_vfx.gd` | `scripts/tests/brunich_combat_vfx_smoke.gd` |
| Diálogo y pausa narrativa | `scenes/tests/Brunich/narrative_overlay.gd`, `npc_narrative.gd` | `scripts/tests/brunich_narrative_overlay_smoke.gd` |
| Paleta y shaders | `scenes/tests/Brunich/brunich_palette.gd` y shaders de esa carpeta | `scripts/tests/brunich_palette_integration_smoke.gd` |

## Componentes y perfiles

`scripts/components/` y `scenes/components/` tienen cinco componentes activos:
salud, hitbox, hurtbox, controlador y velocidad constante. Sus propiedades
`Owner` se asignan desde las entidades; las señales conectan daño y muerte.
No sustituirlos por piezas archivadas sin revisar su contrato.

Las armas `enemy_weapon`, `enemy_spread_weapon`, `enemy_pierce_weapon`,
`enemy_slowbeam_weapon` y `enemy_ai_core_weapon` devuelven
`get_attack_profile_for_player() -> Dictionary`. El pickup conserva ese perfil;
el arma del jugador lo instala y modifica sus valores para el robo.
No asumir que la versión robada tiene exactamente el daño del enemigo.

## Mapas y arte

- `map_generator.gd`: rejilla actual de 32 px, cuatro layouts normales y megacore.
- `art/generated/brunich/brunich_industrial_atlas.res`: atlas actual 128x64,
  ocho roles compatibles con los índices anteriores. Atlas PNG anterior conservado.
- Sala normal: 40x20 tiles. Segunda sala de cada bioma: 200x100 tiles.
  Es un experimento activo, no un sistema terminado de biomas.
- El pintado, decoración, spawns, cámara y luz tienen dueños distintos; un layout
  nuevo requiere revisar todos, no solo agregar una función `_pick_*`.
- `art/generated/brunich/mc_face_expressions.json`: catálogo de expresiones.
- `art/fonts/`: tipografía. `art/decor/`: props. `Songs/`: audio; no reproducirlo
  durante pruebas automatizadas. `art/Beta*` conserva material experimental.

## Historia y texto

La identidad está en `IA_ROGUE_BIBLIA.md`. Los diálogos ejecutados están en
`intro_cinematic.gd`, `rest_zone.gd`, `brunich_tests.gd` y `npc_narrative.gd`.
El Archivista pertenece al hub, no al menú de slots. No reescribir el canon para
justificar un contador o una escena experimental.

## Qué no es juego activo

- `addons/godotgpt/`: integración de editor, separada del gameplay.
- `tmp/`, `.godot/`, `.superpowers/`: salidas/cachés, no fuentes de diseño.
- Los imports nuevos no relacionados no forman parte de la entrega de organización.

## Verificación

`tools/run_visual_tests.ps1` ejecuta una prueba original con audio Dummy y timeout.
`tools/run_suite.ps1` ejecuta secuencialmente las pruebas nativas y los contratos.
`tools/verify_progression_ui.gd` revisa límites de texto y captura menú/hub.
`tools/verify_visual.gd` comprueba atlas, cara, layouts y contratos básicos sin
abrir ningún slot. `tools/verify_project_docs.ps1` comprueba enlaces locales del
directorio y entrada; no sustituye las pruebas del juego.

El estado real de cada prueba se registra en [el plan](PLAN_ORGANIZACION.md).
