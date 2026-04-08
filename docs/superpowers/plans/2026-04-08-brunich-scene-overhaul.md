# Brunich Scene Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rehacer la escena Brunich con un nuevo mapa industrial coherente, un glitch local sin distorsion global y un enemigo notablemente mas duro y agresivo.

**Architecture:** La arena seguira siendo una escena autocontenida de prueba, pero con un atlas propio generado desde `BetaTileSet_updown.png`, layout/collisions definidos en la escena Brunich y una IA enemiga mas rica gobernada desde sus scripts existentes. La verificacion se apoyara en un script de smoke test de Godot para inspeccionar la escena y simular partes del combate.

**Tech Stack:** Godot 4.6, GDScript, TileMapLayer/TileSet, Python PIL para generar atlas, smoke tests ejecutados por linea de comandos.

---

### Task 1: Build verification harness

**Files:**
- Create: `scripts/tests/brunich_scene_smoke.gd`
- Create: `scripts/tests/brunich_render_probe.gd`
- Test: `scenes/tests/Brunich/Brunich_tests.tscn`

- [ ] Step 1: Write the failing smoke test script with expectations for the new atlas, opening, enemy stats and dodge behavior.
- [ ] Step 2: Run `Godot_v4.6.2-stable_win64.exe --path . --headless --script res://scripts/tests/brunich_scene_smoke.gd` and confirm it fails against the current scene.
- [ ] Step 3: Write the render probe that captures baseline, post-shot and glitch frames for investigation.
- [ ] Step 4: Run the render probe and inspect the generated evidence to confirm the distortion source.

### Task 2: Generate Brunich atlas and rebuild arena

**Files:**
- Create: `art/generated/brunich/brunich_updown_atlas.png`
- Modify: `scenes/tests/Brunich/map_generator.gd`
- Modify: `scenes/tests/Brunich/Brunich_tests.tscn`

- [ ] Step 1: Generate a reduced atlas from `BetaTileSet_updown.png` with only coherent floor/wall/depth tiles.
- [ ] Step 2: Replace the current map generator so it builds a 32x32 atlas-backed tileset and paints option B.
- [ ] Step 3: Add the top opening and arena boundaries/collisions in `Brunich_tests.tscn`.
- [ ] Step 4: Re-run the smoke test and confirm the map-related assertions pass.

### Task 3: Fix glitch distortion and improve readability

**Files:**
- Modify: `scenes/tests/Brunich/glitch_shader.gdshader`
- Modify: `scenes/tests/Brunich/test_character_shaders.tscn`
- Modify: `scenes/tests/Brunich/test_character_shaders.gd`

- [ ] Step 1: Replace `SCREEN_TEXTURE` usage with a local overlay glitch effect.
- [ ] Step 2: Tune the MC overlay and floor contrast so the player remains readable.
- [ ] Step 3: Re-run the render probe and smoke test to confirm the background no longer shifts unexpectedly.

### Task 4: Upgrade enemy durability and combat behavior

**Files:**
- Modify: `scenes/tests/Brunich/enemy_regulated.gd`
- Modify: `scenes/tests/Brunich/enemy_weapon.gd`
- Modify: `scenes/tests/Brunich/enemy_projectile.gd`
- Modify: `scenes/tests/Brunich/enemy_regulated.tscn`
- Modify: `scenes/tests/Brunich/projectile_one_shader.gd`

- [ ] Step 1: Increase enemy health and expose combat tuning constants.
- [ ] Step 2: Add tactical movement: maintain distance, strafe and dodge incoming player projectiles.
- [ ] Step 3: Increase pressure with faster shots and burst-like cadence.
- [ ] Step 4: Re-run the smoke test and verify dodge plus projectile pressure behavior.

### Task 5: End-to-end verification

**Files:**
- Test: `scenes/tests/Brunich/Brunich_tests.tscn`

- [ ] Step 1: Run the smoke test script headless and confirm full pass.
- [ ] Step 2: Run Godot against the project scene and confirm it opens without script errors.
- [ ] Step 3: Capture final evidence and summarize residual risks if any remain.
