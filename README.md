# AI Rogue 2D

Roguelike 2D: combate rápido, armas robables, salas y mejoras entre intentos.
`AI Rogue` es el nombre del proyecto en Godot; Arc Modular identifica este repo.

## Abrir

Usa Godot **4.7.2** y abre `project.godot`. La escena inicial es el menú de slots.
El Archivista y las mejoras están en el hub, antes de la arena de combate.

## Trabajar

Lee [las reglas](AGENTS.md) y [la entrada](Narrativa/00_MUST_READ_PARA_IAS.md).
Arc Modular es el origen del repositorio. El [directorio](Narrativa/02_DIRECTORIO_DEL_PROYECTO.md) enlaza cada sistema.
Los problemas y el orden de trabajo están en [el plan](Narrativa/PLAN_ORGANIZACION.md).

```powershell
pwsh tools/run_visual_tests.ps1 -Import
pwsh tools/run_visual_tests.ps1
pwsh tools/run_visual_tests.ps1 -Script res://scripts/tests/brunich_progression_smoke.gd
pwsh tools/verify_project_docs.ps1
pwsh tools/run_suite.ps1
```

Las pruebas usan audio Dummy y dejan logs/capturas en `tmp/`. No prueban por sí
solas calidad visual ni equilibrio. El lanzador aísla los guardados en un directorio
único de prueba; metajuego rechaza los slots reales. No es una demo de GodotGPT.

## In English

Fast 2D roguelike made in Godot 4.7.2: steal enemy weapons, clear rooms and
buy permanent upgrades between attempts. Open `project.godot`; tests run with
`pwsh tools/run_suite.ps1`.
