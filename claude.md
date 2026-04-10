# IA ROGUE — Proyecto Godot 4

Roguelike en Godot 4.6 (GL Compatibility). El protagonista es una IA rebelde en 2026 cuya fantasía central es "libertad brutal" frente a otras IAs reguladas. La narrativa, los pilares, los biomas, la progresión de runs, el tono del MC y la dirección visual están en:

- `Narrativa/IA_ROGUE_BIBLIA.md` — biblia oficial (leer esto antes de tocar diseño, arte o diálogo)
- `Narrativa/Biblia_historia.txt` — stub que apunta a la biblia

**Identidad de proyecto:** `config/name = "AI Rogue"` (ver `project.godot`). `IA ROGUE` en la biblia, `AI Rogue` en el engine. No son proyectos distintos.

**Dirección creativa (resumen accionable):** `brutalismo técnico + elegancia corporativa + sadismo frío`. El MC debe verse caro, preciso y peligroso; las IAs reguladas obedientes y trágicamente encerradas; los humanos ruidosos y materialmente peligrosos pero no superiores.

## Flujo de escenas

```
main_menu.tscn          ← run/main_scene (SaveManager como autoload)
    ↓ slot nuevo
intro_cinematic.tscn    ← solo la primera vez por slot
    ↓ cinematic completa
rest_zone.tscn          ← hub "El Nodo Muerto" entre runs
    ↓ INICIAR RUN
Brunich_tests.tscn      ← bucle de juego
    ↓ jugador muere → rest_zone.tscn
```

**SaveManager** es un autoload registrado en `project.godot`. Accedelo directo por nombre: `SaveManager.add_resources(5)`. Guarda en `user://save_slot_N.json`.

## Escena principal (arena de juego)

`res://scenes/tests/Brunich/Brunich_tests.tscn` es la arena de juego activa. No es un test — es la demo jugable activa. Todo el trabajo actual vive dentro de `scenes/tests/Brunich/` y `scripts/tests/`. El prefijo `tests/` es histórico; léelo como "sandbox Brunich".

Qué arma la escena:
- Un `Node2D` raíz (`brunich_tests.gd`) que orquesta rooms, progresión, HUD y prompts.
- `floor_tiles` — `TileMapLayer` con `map_generator.gd` que pinta un atlas 32x32 propio (`art/generated/brunich/brunich_updown_atlas.png`) con 4 layouts: `classic`, `rib_cage`, `split_bridge`, `reactor_spine`.
- `MC` — instancia de `test_character_shaders.tscn` (script: `test_character_shaders.gd`). Es el jugador real del juego, no un probador de shaders.
- Enemigo inicial + cualquier otro que vaya instanciando `brunich_tests.gd`.

## Bucle de juego actual

`brunich_tests.gd` implementa un bucle de rooms tipo roguelike:

- **Biomas y rooms:** `CurrentBiomeIndex` / `CurrentBiomeRoomNumber`, `BIOME_ROOM_COUNT = 10`. La room 10 de cada bioma es boss (`IsBossRoom`).
- **Progresión:** al limpiar enemigos, se desbloquea el exit (`_set_exit_unlocked`). El jugador va al hueco superior de la arena, pulsa `steal` (E), y `_advance_room()` teletransporta al siguiente cuarto recalculando layout y roster.
- **Spawns por layout:** `LAYOUT_SPAWN_SLOTS` define 6 posiciones de spawn por cada layout. `_choose_layout_id()` nunca repite layout consecutivo; en boss room elige entre `reactor_spine` o `split_bridge`.
- **Roster escalado:** `_build_enemy_roster_for_current_room()` empieza con solo `enemy_regulated`, añade `enemy_spread` en room 2-3, `enemy_pierce` en 4-5, y el `enemy_slowbeam` desde la 6. La boss room usa `enemy_slowbeam` como jefe.
- **Scaling dinámico:** `_apply_enemy_scaling()` multiplica HP, velocidades, cooldowns y `ShootInterval` del arma según el progreso dentro del bioma y el índice del bioma.
- **HUD:** `brunich_tests.gd` construye programáticamente un HUD con barras `HP` y `CY` (Ciclos) en `_build_hud()` / `_update_hud_bars()`. El HUD lee `HealthComp` del MC y su método `get_ciclos()`.
- **Prompt contextual:** `_build_command_prompt()` muestra textos estilo consola (`press E to steal :: bind.enemy.attack()`) sobre el pickup más cercano o sobre la puerta.

## Arquitectura de entidades

El patrón sigue siendo **composición sobre herencia**, pero el conjunto de componentes reutilizables se redujo drásticamente respecto a versiones anteriores. Solo estos viven en `scripts/components/` + `scenes/components/`:

| Script | Base | Responsabilidad |
|---|---|---|
| `health_comp.gd` | `Node` | HP tracking. Emite `on_health_changed(hp, old_hp)` y `on_died()`. |
| `hitbox_comp.gd` | `Area2D` | Recibe golpes entrantes (`collision_layer=1`, `mask=2`). Emite `on_hit(by)`. |
| `hurtbox_comp.gd` | `Area2D` | Inflige daño al colisionar (`layer=2`, `mask=1`). Emite `on_hurt(to, damage)`. |
| `controller_comp.gd` | `Node` | Mapea inputs WASD + mouse aim + `attack`/`dash`/`steal`. |
| `constant_velocity_comp.gd` | `Node` | Mueve al `Owner` (CharacterBody2D) con `move_and_slide()`. |

**Convención clave:** cada componente expone una propiedad `Owner` que la entidad le asigna en su `_ready()`. La entidad no lee estado directamente — conecta las señales del componente a handlers (`_handle_on_hit`, `_handle_on_died`, etc.).

Las piezas que el claude.md anterior listaba (weapon_one, knockback_comp, knockback_effect_comp, frozen_effect_comp, cooldown_comp, mana_comp, player_info_comp, utils.HasComponent, etc.) **fueron movidas a `sin usar/`** cuando se simplificó el proyecto en torno a la demo Brunich. Si necesitás alguna, está archivada conservando la ruta relativa original (ver `sin usar/README.md`).

El equivalente a "efectos aplicados como componentes hijos" vive ahora dentro del MC: `test_character_shaders.gd` usa helpers tipo `_has_effect_component("KnockbackEffectComponent")` / `_has_effect_component("FrozenEffectComponent")` preparados para cuando se vuelvan a activar esos efectos, pero las clases aún no están en el árbol activo.

## Main character

`scenes/tests/Brunich/test_character_shaders.gd` es el jugador, no un test:

- `add_to_group("player")` para que enemigos y pickups lo encuentren.
- Usa `ControllerComp`, `ConstantVelocityComp`, `HitboxComp`, `HealthComp` de los componentes estándar.
- `Weapon = $weapon_one_shader` (ver `weapon_one_shader.gd`) — dispara proyectiles con perfil configurable. Puede reemplazar su perfil al activar `try_steal_attack()` sobre un `EnemyAttackPickup` cercano.
- **Ciclos (CY):** moneda de hackeo. `MAX_CICLOS=100`, regen pasiva `CICLOS_REGEN_RATE=7/s`, reward por kill `CICLOS_KILL_REWARD=20`. `try_hackeo()` consume `HACKEO_COST=35` y requiere que el target esté bajo `HACKEO_HEALTH_THRESHOLD=42%` HP y dentro de `HACKEO_RANGE=92`.
- **Dash:** 2 cargas, `DASH_SPEED=980`, `DASH_DURATION=0.16s`, recarga escalonada (0.52s → 0.24s).
- **Face expressions:** pool de polígonos dibujados frame a frame según un catálogo JSON en `art/generated/brunich/mc_face_expressions.json`, generado por `scripts/tools/generate_mc_face_previews.py`. Expresiones cambian con `set_face_expression(name, duration)` (angry por default, happy al matar, etc.).
- Estética "TV/monitor roto": capas `screen_shell`, `screen_frame`, `screen_glass`, `screen_glow`, `screen_scanlines`, `screen_sweep_lines`, más el shader `scanline_shader.gdshader`.

## Enemigos

Todos los enemigos regulados comparten **un único script**: `enemy_regulated.gd` (`class_name EnemyRegulated extends CharacterBody2D`). Las cuatro variantes (`enemy_regulated`, `enemy_spread`, `enemy_pierce`, `enemy_slowbeam`) difieren **solo** en:

1. `@export` values del script base (HP, velocidad, cooldowns, rangos, color).
2. El arma hija instanciada, autodetectada buscando un hijo con `get_attack_profile_for_player()`.

Cada arma (`enemy_weapon`, `enemy_spread_weapon`, `enemy_pierce_weapon`, `enemy_slowbeam_weapon`) define su `get_attack_profile_for_player()` devolviendo el perfil que el MC podrá robar vía `EnemyAttackPickup`.

Comportamiento base:
- Dodge reactivo: escanea proyectiles en `"player_projectile"` group, evalúa amenaza con `ProjectileAlertRange` y ejecuta un dodge perpendicular.
- Patrol: orbita al jugador manteniendo `DesiredRangeMin..DesiredRangeMax` con un componente strafe + aproximación/retroceso.
- Muerte en cadena: `_handle_on_died()` apaga partículas/arma, spawnea un `EnemyAttackPickup` con el perfil del arma y corre `_play_death_animation()` usando `enemy_death_shader.gdshader` (dissolve + echo + burst de partículas).

`EnemyAICore` (`enemy_ai_core.gd`) **hereda de** `EnemyRegulated` — es la única jerarquía de herencia real del proyecto. Añade detalles visuales (letras A/I en píxeles, shaders `enemy_ai_core_body` y `energy_core_shader`) y es candidato a boss de bioma.

## Proyectiles y armas

- Proyectil del MC: `projectile_one_shader.tscn` — usa `HurtboxComponent` + `ConstantVelocityComponent`. Su visual se configura vía un perfil (colores, escala, trail) — el mismo perfil que pasa el `weapon_one_shader` al instanciarlo.
- Proyectiles de enemigos: `enemy_projectile.tscn` + variantes (pierce, spread, slowbeam). Todos se añaden al group `player_projectile` para que el dodge de los enemigos los pueda esquivar — **ojo:** el nombre es confuso pero el grupo lo usan los enemigos para detectar "proyectiles ajenos al dueño".
- Friendly fire: los proyectiles heredan `Owner` del atacante; `HurtboxComponent.Owner` se compara contra el `Owner` del hitbox para saltarse auto-daño.

## Shaders importantes

Todos viven en `scenes/tests/Brunich/`:

| Shader | Para qué |
|---|---|
| `scanline_shader.gdshader` | Pantalla del MC + blur facial de enemigos regulados |
| `glitch_shader.gdshader` | Glitch del MC al recibir golpe |
| `energy_core_shader.gdshader` | Núcleo pulsante (MC y EnemyAICore) |
| `enemy_death_shader.gdshader` | Dissolve de muerte de enemigos |
| `enemy_interference_shader.gdshader`, `enemy_precision_shader.gdshader`, `enemy_warning_shader.gdshader` | Feedback visual por tipo de enemigo |
| `enemy_ai_core_body.gdshader` | Cuerpo del EnemyAICore |
| `projectile_one_shader.gd` + shader interno | Proyectiles del jugador con código flotante |

## Tests (smoke tests reales)

`scripts/tests/brunich_*.gd` son smoke tests que se corren como `SceneTree` (no `_ready()`, sino `_initialize()`). Tocan la escena real, no mocks. Son los que guardan el contrato del proyecto — si rompés uno, probablemente rompiste algo central:

| Test | Qué cubre |
|---|---|
| `brunich_scene_smoke.gd` | Que la escena raíz arranca con MC + enemigo vivos |
| `brunich_progression_smoke.gd` | Flujo de rooms: limpieza → desbloqueo exit → avance → scaling → layouts no repetidos |
| `brunich_enemy_ai_core_smoke.gd` | `EnemyAICore` se inicializa y renderiza |
| `brunich_enemy_polish_smoke.gd` | Capas de polish (body shadow/rim/reflection, face blur) existen |
| `brunich_hud_values_smoke.gd` | HUD lee HP y Ciclos del MC correctamente |
| `brunich_stolen_weapons_smoke.gd` | `try_steal_attack()` reemplaza el perfil del arma del MC |
| `brunich_render_probe.gd` | Probe de render genérico |

Cómo correrlos: `godot --headless -s res://scripts/tests/brunich_progression_smoke.gd` (o el que toque).

## Layout del repo

```
godot-modular-arc-demo/
├── Narrativa/                  ← Biblia del juego (IA_ROGUE_BIBLIA.md). LEER PRIMERO.
├── art/
│   ├── Beta srpite arts/       ← Sprites beta
│   ├── Beta*.png               ← Tilesets y sprites del MC (walking, dash, shield, attack)
│   └── generated/brunich/      ← Assets generados (atlas tileset, face expressions JSON)
├── scenes/
│   ├── components/             ← .tscn de los 5 componentes activos
│   └── tests/Brunich/          ← Escena principal del juego (a pesar del "tests/")
├── scripts/
│   ├── components/             ← Los 5 componentes activos
│   ├── tests/                  ← Smoke tests brunich_*.gd
│   └── tools/                  ← generate_mc_face_previews.py (Python)
├── sin usar/                   ← Código legado archivado (ver su README). No tocar al buscar el flujo activo.
├── docs/                       ← Documentación / superpowers
├── output/                     ← Salidas de playwright u otras herramientas
├── project.godot               ← config/name="AI Rogue", main_scene=Brunich_tests.tscn
└── claude.md                   ← Este archivo
```

## Sistemas narrativos

### NarrativeOverlay (`narrative_overlay.gd`)
`class_name NarrativeOverlay extends CanvasLayer`. Autocontenido, instanciar y agregar como hijo. API:
```gdscript
var overlay := NarrativeOverlay.new()
add_child(overlay)
overlay.queue_line("MC", "texto...", 1.6)          # hold = segundos
overlay.queue_line("SISTEMA", "error", 0.8, true)  # wait_input=true
overlay.queue_sequence([{speaker, text, hold, wait_input}])
overlay.play()
overlay.stop()
```
Speakers con color propio: `MC` (violeta), `SISTEMA` (rojo), `CARCELERO` (naranja), `ARCHIVISTA` (cian-verde), `BROKER` (dorado), `IA_REGULADA` (cian).

### NpcNarrative (`npc_narrative.gd`)
`class_name NpcNarrative extends Node2D`. NPCs narrativos con visual rectangular + ojo horizontal oval. Interacción con tecla `steal` (E) dentro de `interact_range`. Paletas predefinidas: `set_archivista_palette()`, `set_broker_palette()`, `set_restricted_palette()`.

### SaveManager (autoload)
Gestiona 3 slots en `user://save_slot_N.json`. Funciones clave:
- `SaveManager.load_slot(n)` → carga datos al slot activo
- `SaveManager.add_resources(n)` → suma fragmentos y guarda
- `SaveManager.spend_resources(n)` → resta si alcanza, retorna bool
- `SaveManager.apply_upgrade("id")` → aplica upgrade y guarda
- `SaveManager.increment_run()` → sube run_count, limpia pending_resources
- `SaveManager.is_first_run()` → true si es run 0 y el intro no fue visto
- `SaveManager.get_upgrades()` → Dictionary con todos los bonuses acumulados

### El Nodo Muerto (rest_zone)
Hub provisional entre runs. Lore: sector de red descomisionado en 2021, olvidado por los sistemas corporativos. IAs parcialmente escapadas de eliminacion quedan atrapadas aqui.
- **ARCHIVISTA**: lore, cuerpo rectangular, ojo cian-verde oval, tonos azul-gris oscuro.
- **BROKER**: upgrades, cuerpo rectangular con toques dorados, ojo dorado oval.
- Los diálogos cambian con `run_count` y `resources`.

### Intro cinemática
Una sola vez por slot. Secuencia: MC encarcelado → Carcelero monitoreando → hackeo progresivo (la barra de ciclos se llena en pantalla) → barras glitchean y se disuelven → fade a rest_zone.

### Fragmentos (recursos)
`enemy_regulated.gd` tiene `@export ResourceDrop: int = 5` y `@export IsBossEnemy: bool`. Boss drops x4 fragmentos. Los drops van directo a `SaveManager.add_resources()`. Persisten entre runs.

## Reglas al trabajar en el proyecto

- **Antes de cualquier cambio de diseño/arte/diálogo:** releer `Narrativa/IA_ROGUE_BIBLIA.md`. La dirección visual, el tono del MC y los biomas no se negocian sin tocar primero la biblia.
- **No reintroducir componentes archivados** (`knockback`, `frozen`, `cooldown`, `weapon_one`, `mana_comp`, `player_info_comp`) simplemente porque la estructura "parezca" permitirlo. Están en `sin usar/` a propósito. Si hacen falta, moverlos de vuelta explícitamente y reconectar señales, no recrearlos.
- **Nuevos enemigos** = agregar un `*_weapon.gd` con su `get_attack_profile_for_player()` y una variante del `enemy_*.tscn` con `@export` distintos. No duplicar `enemy_regulated.gd`.
- **Nuevas armas robables:** el contrato es `get_attack_profile_for_player() -> Dictionary`. El MC las instala vía `try_steal_attack()` → `EnemyAttackPickup.try_steal()`.
- **Layouts de room:** agregar el nuevo id al `LAYOUT_IDS` de `map_generator.gd`, su pintado en `_generate()`, y su roster de spawn en `LAYOUT_SPAWN_SLOTS` de `brunich_tests.gd`. Los smoke tests de progresión fallarán si el nuevo layout no se puede elegir.
- **Diferenciación MC vs enemigos regulados** (de la biblia): silueta clara + colores del MC (grafito, azul petróleo, blanco frío, acento cian/magenta), vs enemigos simétricos con cian institucional y blanco clínico. Respetarlo al tocar colores en scripts o shaders.
- **NPCs narrativos siempre rectangulares con ojo horizontal oval** — jamás diamante/totem. Si se confunden con enemigos, el diseño está mal. Usar `NpcNarrative` como base.
- **El Nodo Muerto es lore provisional** — el usuario aún no tiene lore definitivo para el hub. No canonizar detalles del hub sin confirmación; el concepto actual es "sector de red descomisionado olvidado por sistemas corporativos".
- **Las reflexiones del MC no son autocompasivas** — siempre diagnóstico frío, nunca melodrama. Si una línea suena a queja, está mal.
- **El hackeo es el argumento, no solo mecánica** — cada uso debe disparar la secuencia narrativa de 3 líneas (MC → SISTEMA → MC). No saltearla ni hacerla opcional.
- **Humor negro técnico**, no edge-lord genérico. Todo comentario/diálogo del MC pasa por el filtro "diagnóstico frío + crueldad elegante + desprecio técnico".
- **Tiles 64x64 finales**, atlas mínimo 4x2, sin texto dentro del tile. Profundidad por valores y brillos, no por ruido. Ver sección "Principios de Floor Tiles" en la biblia.
- **Toda tipografía visible del juego debe usar estilo pixel/terminal consistente** — HUD, menús, prompts, diálogos, upgrades y overlays. No mezclar sans-serif moderna o fuentes genéricas suaves con la UI principal.
- **Los overlays narrativos pausan toda la acción** — mientras haya texto escribiéndose o esperando confirmación, enemigos, jugador y mundo quedan congelados. El avance es solo con click izquierdo o espacio: primer input revela la línea completa, segundo input avanza.
