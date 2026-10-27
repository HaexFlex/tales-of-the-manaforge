extends SceneTree
## Keeper attack contact sheet: logical frames 1, 4, 8 (1×) with wpn_sword_t0 vs wpn_sword_t2.
## godot --headless --path . --script res://tools/r6_combat_contact_sheet.gd

const CombatAnimsConfigScript := preload("res://scripts/battle/combat_anims_config.gd")

const OUT_PATH: String = "/opt/cursor/artifacts/keeper_attack_weapons_contact.png"
const ACTOR: String = "keeper"
const CLIP: String = "attack"
const LOGICAL_FRAMES_1: Array[int] = [1, 4, 8]
const LOGICAL_TOTAL: int = 8
const WEAPON_TIERS: Array[String] = [
	"res://assets/art/battle/weapons/wpn_sword_t0.png",
	"res://assets/art/battle/weapons/wpn_sword_t2.png",
]
const CELL: int = 128
const PAD: int = 8
const GRIP: Vector2 = Vector2(0.0, 3.0)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	CombatAnimsConfigScript.reload()
	var cols: int = LOGICAL_FRAMES_1.size()
	var rows: int = WEAPON_TIERS.size()
	var sheet_w: int = cols * CELL + PAD * (cols + 1)
	var sheet_h: int = rows * CELL + PAD * (rows + 1)
	var sheet := Image.create(sheet_w, sheet_h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.08, 0.12, 0.1, 1.0))
	for tier_i: int in WEAPON_TIERS.size():
		var weapon: Image = _load_png(WEAPON_TIERS[tier_i])
		if weapon == null:
			push_error("missing weapon %s" % WEAPON_TIERS[tier_i])
			quit(1)
			return
		for frame_i: int in LOGICAL_FRAMES_1.size():
			var logical_1: int = LOGICAL_FRAMES_1[frame_i]
			var logical_0: int = logical_1 - 1
			var art_frame: int = CombatAnimsConfigScript.art_frame_for_logical(
				ACTOR, CLIP, logical_0, LOGICAL_TOTAL,
			)
			var body_path: String = CombatAnimsConfigScript.modular_body_path(ACTOR, CLIP, art_frame)
			var body: Image = _load_png(body_path)
			if body == null:
				push_error("missing body %s" % body_path)
				quit(1)
				return
			var anchor: Dictionary = CombatAnimsConfigScript.hand_anchor(ACTOR, CLIP, art_frame)
			var ox: int = PAD + frame_i * (CELL + PAD)
			var oy: int = PAD + tier_i * (CELL + PAD)
			_blit_frame(sheet, body, weapon, anchor, ox, oy)
	DirAccess.make_dir_recursive_absolute("/opt/cursor/artifacts")
	if sheet.save_png(OUT_PATH) != OK:
		push_error("failed to write %s" % OUT_PATH)
		quit(1)
		return
	print("CONTACT_SHEET_OK: %s" % OUT_PATH)
	quit(0)


func _load_png(path: String) -> Image:
	var img := Image.new()
	if img.load(path) != OK:
		return null
	if img.is_compressed():
		img.decompress()
	return img


func _blit_frame(sheet: Image, body: Image, weapon: Image, anchor: Dictionary, ox: int, oy: int) -> void:
	for y: int in CELL:
		for x: int in CELL:
			if x < body.get_width() and y < body.get_height():
				sheet.set_pixel(ox + x, oy + y, body.get_pixel(x, y))
	var hx: int = int(anchor.get("hand_x", 0))
	var hy: int = int(anchor.get("hand_y", 0))
	var rot_index: int = int(anchor.get("rot_index", 0))
	var rot: float = CombatAnimsConfigScript.weapon_rotation_rad(rot_index)
	_blit_weapon_rotated(sheet, weapon, ox + hx, oy + hy, rot)


func _blit_weapon_rotated(sheet: Image, weapon: Image, hand_x: int, hand_y: int, rot_rad: float) -> void:
	var grip: Vector2 = GRIP
	for wy_i: int in weapon.get_height():
		for wx_i: int in weapon.get_width():
			var local: Vector2 = Vector2(float(wx_i), float(wy_i)) - grip
			if not is_equal_approx(rot_rad, 0.0):
				local = local.rotated(rot_rad)
			var px: int = int(round(hand_x + local.x))
			var py: int = int(round(hand_y + local.y))
			if px < 0 or py < 0 or px >= sheet.get_width() or py >= sheet.get_height():
				continue
			var c: Color = weapon.get_pixel(wx_i, wy_i)
			if c.a < 0.05:
				continue
			var under: Color = sheet.get_pixel(px, py)
			sheet.set_pixel(px, py, under.lerp(c, c.a))
