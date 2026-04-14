extends RefCounted
class_name BrunichPalette

const VOID_BG := Color8(14, 7, 27, 255)
const ROOM_SHADOW := Color8(26, 25, 50, 255)
const ROOM_METAL_DARK := Color8(42, 47, 78, 255)
const ROOM_METAL_BASE := Color8(66, 76, 110, 255)
const ROOM_METAL_SOFT := Color8(101, 115, 146, 255)
const ROOM_METAL_EDGE := Color8(199, 207, 221, 255)
const ROOM_PANEL_DARK := Color8(39, 39, 39, 255)
const ROOM_PANEL_MID := Color8(61, 61, 61, 255)
const ROOM_PANEL_LIGHT := Color8(93, 93, 93, 255)

const ACCENT_COLD_DIM := Color8(12, 46, 68, 255)
const ACCENT_COLD := Color8(0, 152, 220, 255)
const ACCENT_COLD_HOT := Color8(148, 253, 255, 255)
const ACCENT_OBJECTIVE := Color8(255, 200, 37, 255)
const ACCENT_OBJECTIVE_SOFT := Color8(246, 202, 159, 255)
const ACCENT_HP := Color8(234, 50, 60, 255)
const ACCENT_HP_SOFT := Color8(245, 85, 93, 255)
const ACCENT_THOUGHT := Color8(122, 9, 250, 255)
const ACCENT_THOUGHT_SOFT := Color8(202, 82, 201, 255)
const ACCENT_THOUGHT_HOT := Color8(243, 137, 245, 255)

const HUD_FRAME := Color8(42, 47, 78, 255)
const HUD_BG := Color8(27, 27, 27, 255)
const HUD_TEXT := Color8(249, 230, 207, 255)
const HUD_OUTLINE := Color8(14, 7, 27, 255)
const TERMINAL_BG := Color8(12, 25, 63, 255)
const TERMINAL_LINE := Color8(0, 105, 170, 255)
const TERMINAL_TEXT := Color8(148, 253, 255, 255)

const HERO_FRAME_IDLE := Color8(27, 27, 27, 255)
const HERO_FRAME_ACTIVE := Color8(66, 76, 110, 255)
const HERO_SHELL_IDLE := Color8(14, 7, 27, 255)
const HERO_SHELL_ACTIVE := Color8(28, 18, 28, 255)
const HERO_TRIM_IDLE := Color8(66, 76, 110, 255)
const HERO_TRIM_ACTIVE := Color8(148, 253, 255, 255)
const HERO_FILL_IDLE := Color8(61, 61, 61, 255)
const HERO_FILL_ACTIVE := Color8(93, 93, 93, 255)
const HERO_GLOW_IDLE := Color8(0, 105, 170, 255)
const HERO_GLOW_ACTIVE := Color8(202, 82, 201, 255)
const HERO_PIXEL_IDLE := Color8(199, 207, 221, 255)
const HERO_PIXEL_ALERT := Color8(249, 230, 207, 255)
const HERO_PARTICLE_DARK := Color8(48, 3, 217, 255)
const HERO_PARTICLE_BASE := Color8(12, 2, 147, 255)
const HERO_PARTICLE_BRIGHT := Color8(202, 82, 201, 255)
const HERO_TRAIL := Color8(98, 36, 97, 255)
const HERO_SWAP_BACK := Color8(94, 197, 79, 255)
const HERO_SWAP_FRONT := Color8(211, 252, 126, 255)

const HERO_PROJECTILE_OUTER := Color8(243, 137, 245, 255)
const HERO_PROJECTILE_CORE := Color8(59, 20, 67, 255)
const HERO_PROJECTILE_CODE := Color8(249, 230, 207, 255)
const HERO_PROJECTILE_TRAIL := Color8(202, 82, 201, 255)

const ENEMY_COLD_OUTER := Color8(12, 241, 255, 255)
const ENEMY_COLD_CORE := Color8(0, 57, 109, 255)
const ENEMY_COLD_CODE := Color8(249, 230, 207, 255)
const ENEMY_COLD_TRAIL := Color8(0, 152, 220, 255)
const ENEMY_WARM_OUTER := Color8(255, 162, 20, 255)
const ENEMY_WARM_CORE := Color8(57, 31, 33, 255)
const ENEMY_WARM_CODE := Color8(249, 230, 207, 255)

static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, clampf(alpha, 0.0, 1.0))

static func lift(color: Color, amount: float) -> Color:
	return color.lerp(ROOM_METAL_EDGE, clampf(amount, 0.0, 1.0))

static func deepen(color: Color, amount: float) -> Color:
	return color.lerp(VOID_BG, clampf(amount, 0.0, 1.0))
