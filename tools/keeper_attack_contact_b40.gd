extends SceneTree
## Engine contact sheet (Texture2D layout = battle_view): Keeper attack 1–8 × 4 weapon tiers.
## godot --headless --path . --script res://tools/keeper_attack_contact_b40.gd

const CombatAnimsConfigScript := preload("res://scripts/battle/combat_anims_config.gd")

const OUT_PATH: String = "/cursor/stores/self/caps/keeper_attack_contact_b40.png"
const ACTOR: String = "keeper"
const CLIP: String = "attack"
const LOGICAL_TOTAL: int = 8
const WEAPON_IDS: Array[String] = [
	"wpn_sword_t1",
	"wpn_sword_t2",
	"wpn_bow_t1",
	"wpn_wand_t2",
]
const CELL: int = 128
const PAD: int = 6
const FIGHTER_SOLE: Vector2 = Vector2(64.0, 123.0)


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
		for logical_0: int in LOGICAL_TOTAL:
			var ox: int = PAD + logical_0 * (CELL + PAD)
			var oy: int = PAD + row_i * (CELL + PAD)
			_paint_cell(sheet, sprite_id, logical_0, ox, oy)
	DirAccess.make_dir_recursive_absolute("/cursor/stores/self/caps")
	if sheet.save_png(OUT_PATH) != OK:
		push_error("failed to write %s" % OUT_PATH)
		quit(1)
		return
	print("CONTACT_B40_OK: %s" % OUT_PATH)
	quit(0)


func _paint_cell(sheet: Image, sprite_id: String, logical_0: int, ox: int, oy: int) -> void:
	var art_frame: int = CombatAnimsConfigScript.art_frame_index(
		ACTOR, CLIP, logical_0, LOGICAL_TOTAL,
	)
	var body_path: String = CombatAnimsConfigScript.modular_body_path(ACTOR, CLIP, art_frame)
	var anchor: Dictionary = CombatAnimsConfigScript.hand_anchor(ACTOR, CLIP, art_frame)
	var rot_index: int = int(anchor.get("rot_index", 0))
	var z: String = str(anchor.get("z", "front"))
	var body: Image = _texture_image(body_path)
	var weapon_path: String = CombatAnimsConfigScript.weapon_texture_for_rot(sprite_id, rot_index)
	var weapon: Image = _texture_image(weapon_path)
	if body == null or weapon == null:
		push_error("missing art for cell %s f%d" % [sprite_id, logical_0])
		quit(1)
		return
	if z == "behind":
		_blit_weapon(sheet, weapon, sprite_id, rot_index, anchor, ox, oy)
		_blit_body(sheet, body, ox, oy)
	else:
		_blit_body(sheet, body, ox, oy)
		_blit_weapon(sheet, weapon, sprite_id, rot_index, anchor, ox, oy)


func _texture_image(path: String) -> Image:
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		return null
	var img: Image = tex.get_image()
	if img != null and img.is_compressed():
		img.decompress()
	return img


func _blit_body(sheet: Image, body: Image, ox: int, oy: int) -> void:
	for y: int in mini(CELL, body.get_height()):
		for x: int in mini(CELL, body.get_width()):
			var c: Color = body.get_pixel(x, y)
			if c.a < 0.01:
				continue
			var px: int = ox + x - int(FIGHTER_SOLE.x)
			var py: int = oy + y - int(FIGHTER_SOLE.y)
			if px < 0 or py < 0 or px >= sheet.get_width() or py >= sheet.get_height():
				continue
			sheet.set_pixel(px, py, c)


func _blit_weapon(
	sheet: Image,
	weapon: Image,
	sprite_id: String,
	rot_index: int,
	anchor: Dictionary,
	ox: int,
	oy: int,
) -> void:
	var hx: int = int(anchor.get("hand_x", 0))
	var hy: int = int(anchor.get("hand_y", 0))
	var pivot: Vector2 = CombatAnimsConfigScript.weapon_pivot_for_rot(sprite_id, rot_index)
	var base_x: int = ox + hx - int(pivot.x)
	var base_y: int = oy + hy - int(pivot.y)
	for wy_i: int in weapon.get_height():
		for wx_i: int in weapon.get_width():
			var c: Color = weapon.get_pixel(wx_i, wy_i)
			if c.a < 0.05:
				continue
			var px: int = base_x + wx_i
			var py: int = base_y + wy_i
			if px < 0 or py < 0 or px >= sheet.get_width() or py >= sheet.get_height():
				continue
			var under: Color = sheet.get_pixel(px, py)
			sheet.set_pixel(px, py, under.lerp(c, c.a))
