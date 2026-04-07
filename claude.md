# Godot Modular Arc Demo

## Core Principle: Composition Over Inheritance

Entities are thin orchestrators. Logic lives in reusable child-node components, not in inherited classes. No deep inheritance chains — entities extend only the base Godot type they need (e.g., `CharacterBody2D`) and compose behavior through components.

## Entity Structure

Entities (CharacterBody2D) declare child nodes for each behavior they need:

```
character_one (CharacterBody2D)       # thin root — only coordinates components
├── hitbox_comp  (HitboxComponent)    # Area2D — receives incoming hits
├── health_comp  (HealthComponent)    # Node  — tracks HP
├── controller_comp (ControllerComponent) # Node — reads input
├── constant_velocity_comp (ConstantVelocityComponent) # Node — applies movement
└── weapon_one   (WeaponOne)          # Node2D — shoots projectiles
```

The entity script connects to component signals in `_ready()` and reacts in handler methods (`_handle_on_hit`, `_handle_on_died`, etc.). It does not reach into components to read state directly — it listens to signals.

## Components

| Script | Scene | Base | Responsibility |
|---|---|---|---|
| `health_comp.gd` | `health_comp.tscn` | Node | HP tracking, death signal |
| `hitbox_comp.gd` | `hitbox_comp.tscn` | Area2D | Detects incoming collisions (layer 1, mask 2) |
| `hurtbox_comp.gd` | `hurtbox_comp.tscn` | Area2D | Deals damage on collision (layer 2, mask 1) |
| `constant_velocity_comp.gd` | `constant_velocity_comp.tscn` | Node | Moves owner via `move_and_slide()` |
| `controller_comp.gd` | `controller_comp.tscn` | Node | Maps keyboard/gamepad input to direction vectors |
| `knockback_comp.gd` | `knockback_comp.tscn` | Node | Applies knockback to a target CharacterBody2D |
| `knockback_effect_comp.gd` | `knockback_effect_comp.tscn` | Node | Temporary impulse effect (self-removes when force depletes) |
| `frozen_effect_comp.gd` | `frozen_effect_comp.tscn` | Node | Temporary freeze effect (self-removes after duration) |
| `cooldown_comp.gd` | `cool_down_comp.tscn` | Node | Generic timer; emits `cooldown_start` / `cooldown_end` |
| `player_info_comp.gd` | `player_info_comp.tscn` | Control | UI label showing player name + stats |
| `mana_comp.gd` | — | Node | Stub — not yet implemented |

### Owner property

Most components hold an `Owner` property (set in the scene or in `_ready()`) that references the parent entity. This lets a component reach back to its host (e.g., `constant_velocity_comp` calls `owner.move_and_slide()`).

## Collision Layers

| Layer | Mask | Used by |
|---|---|---|
| 1 | 2 | HitboxComponent — receives from hurtboxes |
| 2 | 1 | HurtboxComponent — hits hitboxes |

Projectiles take the `Owner`'s reference to skip friendly-fire checks.

## Dynamic Effect Composition

Status effects are components added at runtime as children of the target:

```gdscript
# KnockbackComponent._apply_knockback_to_character(target)
var effect = KnockbackEffectComponent.new()
effect.Owner = target
target.add_child(effect)
```

Effects self-destruct (via `queue_free()`) when their duration or force depletes. `Utils.HasComponent()` checks for active effects to suppress movement:

```gdscript
# utils.gd
static func HasComponent(parent: Node, comp_class_name: StringName) -> bool
```

## Signal Flow

```
Input
  └─► ControllerComponent
          └─► entity._input() reads direction/aim/shoot
                  ├─► ConstantVelocityComponent.Direction  → move_and_slide()
                  └─► WeaponOne._shoot(direction)          → spawns ProjectileOne

Collision
  HurtboxComponent.area_entered
      └─► on_hurt(to, damage_dealt) signal
              └─► target HitboxComponent.on_hit(by) signal
                      └─► entity._handle_on_hit()
                              └─► HealthComponent.take_damage()
                                      └─► on_health_changed(hp, old_hp)
                                              └─► entity / UIManager update UI
                                          on_died()
                                              └─► entity._handle_on_died() → queue_free()
```

## Adding a New Component

1. Create `scripts/components/my_thing_comp.gd` — extend the appropriate Godot base type.
2. Expose an `Owner` export if the component needs to interact with its entity.
3. Define signals for outputs; never call entity methods directly.
4. Create `scenes/components/my_thing_comp.tscn` and attach the script.
5. Add the scene as a child node in the entity scene that needs it.
6. In the entity script's `_ready()`, get the node reference and connect its signals.

## Adding a New Entity

1. Create a scene under `scenes/entities/` extending `CharacterBody2D` (or `Node2D` for non-physics entities).
2. Add the component scenes it needs as children — do not rewrite component logic in the entity script.
3. Create the matching script under `scripts/entities/`.
4. The script should only: get component node references, connect signals, and implement handler methods.