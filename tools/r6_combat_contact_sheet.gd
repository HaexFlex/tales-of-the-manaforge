extends SceneTree
## Keeper attack frames 1–8: rows sword t0, sword t2, bow t1, wand t1.
## godot --headless --path . --script res://tools/r6_combat_contact_sheet.gd

const CombatAnimsConfigScript := preload("res://scripts/battle/combat_anims_config.gd")

const OUT_PATH: String = "/opt/cursor/artifacts/keeper_attack_weapons_contact.png"
const ACTOR: String = "keeper"
const CLIP: String = "attack"
const LOGICAL_TOTAL: int = 8
const WEAPON_IDS: Array[String] = [
	"wpn_sword_t0",
	"wpn_sword_t2",
	"wpn_bow_t1",
	"wpn_wand_t1",
]
const CELL: int = 128
const PAD: int = 6


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	CombatAnimsConfigScript.reload()
	var cols: int = LOGICAL_TOTAL
	var rows: int = WEAPON_IDS.size()
	var sheet_w: int = cols * CELL + PAD * (cols + 1)
	var sheet_h: int = rows * CELL + PAD * (rows + 1)
	var sheet := Image.create(sheet_w, sheet_h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.08, 0.12, 0.1, 1.0))
	for row_i: int in WEAPON_IDS.size():
		var sprite_id: String = WEAPON_IDS[row_i]
		for logical_1: int in range(1, LOGICAL_TOTAL + 1):
			var logical_0: int = logical_1 - 1
			var art_frame: int = CombatAnimsConfigScript.art_frame_index(
				ACTOR, CLIP, logical_0, LOGICAL_TOTAL,
			)
			var body_path: String = CombatAnimsConfigScript.modular_body_path(ACTOR, CLIP, art_frame)
			var body: Image = _load_png(body_path)
			if body == null:
				push_error("missing body %s" % body_path)
				quit(1)
				return
			var anchor: Dictionary = CombatAnimsConfigScript.hand_anchor(ACTOR, CLIP, art_frame)
			var rot_index: int = int(anchor.get("rot_index", 0))
			var weapon_path: String = CombatAnimsConfigScript.weapon_texture_for_rot(sprite_id, rot_index)
			var weapon: Image = _load_png(weapon_path)
			if weapon == null:
				push_error("missing weapon %s" % weapon_path)
				quit(1)
				return
			var ox: int = PAD + logical_0 * (CELL + PAD)
			var oy: int = PAD + row_i * (CELL + PAD)
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
	var grip: Vector2 = CombatAnimsConfigScript.WEAPON_GRIP
	var wx: int = ox + hx - int(grip.x)
	var wy: int = oy + hy - int(grip.y)
	for wy_i: int in weapon.get_height():
		for wx_i: int in weapon.get_width():
			var px: int = wx + wx_i
			var py: int = wy + wy_i
			if px < 0 or py < 0 or px >= sheet.get_width() or py >= sheet.get_height():
				continue
			var c: Color = weapon.get_pixel(wx_i, wy_i)
			if c.a < 0.05:
				continue
			var under: Color = sheet.get_pixel(px, py)
			sheet.set_pixel(px, py, under.lerp(c, c.a))
