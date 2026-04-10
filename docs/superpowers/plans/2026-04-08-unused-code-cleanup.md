# Unused Code Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move legacy scenes and scripts that are outside the active Brunich flow into a dedicated `sin usar` folder without breaking the current playable scene.

**Architecture:** Build the dependency closure from `res://scenes/tests/Brunich/Brunich_tests.tscn` and the Brunich smoke/probe scripts, then move only files outside that closure. Preserve relative structure under `sin usar` so legacy content stays recoverable and readable.

**Tech Stack:** Godot 4.6, GDScript, `.tscn` scene resources, PowerShell verification

---

### Task 1: Freeze the Brunich Dependency Boundary

**Files:**
- Modify: `project.godot`
- Inspect: `scenes/tests/Brunich/Brunich_tests.tscn`
- Inspect: `scripts/tests/brunich_scene_smoke.gd`
- Inspect: `scripts/tests/brunich_render_probe.gd`

- [ ] Confirm Brunich is still the active `run/main_scene`.
- [ ] Use a reference scan to list reachable scenes/scripts from the Brunich scene and smoke scripts.
- [ ] Mark everything outside that closure as cleanup candidates.

### Task 2: Archive Legacy Scene/Script Sets

**Files:**
- Move: `scenes/main.tscn`
- Move: `scenes/entities/**`
- Move: `scenes/weapons/**`
- Move: `scenes/tests/wissens/**`
- Move: `scenes/tests/brunich_tests.tscn`
- Move: `scenes/tests/charls_tests.tscn`
- Move: `scenes/tests/pato_tests.tscn`
- Move: `scenes/tests/rodo_tests.tscn`
- Move: `scripts/entities/**`
- Move: `scripts/weapons/**`
- Move: `scripts/ui_manager.gd`
- Move: `scripts/utils/utils.gd`
- Move: unused component scripts/scenes and orphan `.uid` files

- [ ] Create `sin usar/scenes/...` and `sin usar/scripts/...` mirrors.
- [ ] Move each unreachable file together with its `.uid` companion when present.
- [ ] Keep Brunich files, shared live components, and Brunich test scripts in place.

### Task 3: Verify the Active Build Still Runs

**Files:**
- Verify: `scenes/tests/Brunich/**`
- Verify: `scripts/tests/brunich_scene_smoke.gd`

- [ ] Run the Brunich headless smoke test.
- [ ] Launch the project briefly with `--quit-after` to confirm the active scene still opens.
- [ ] Review any errors for broken resource paths before calling the cleanup complete.
