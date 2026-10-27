extends SceneTree
## Keeper attack contact sheet: body frame 2 with wpn_sword_t0 vs wpn_sword_t2.
## godot --headless --path . --script res://tools/r6_combat_contact_sheet.gd

const OUT_PATH: String = "/opt/cursor/artifacts/keeper_attack_weapons_contact.png"
const BODY_PATH: String = "res://assets/art/battle/modular/keeper/attack/frame_0002.png"
const WEAPON_T0: String = "res://assets/art/battle/weapons/wpn_sword_t0.png"
const WEAPON_T2: String = "res://assets/art/battle/weapons/wpn_sword_t2.png"
const HAND_X: int = 112
const HAND_Y: int = 63
const GRIP: Vector2 = Vector2(0.0, 3.0)
const CELL: int = 128
const PAD: int = 8


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var body: Image = _load_png(BODY_PATH)
	var w0: Image = _load_png(WEAPON_T0)
	var w2: Image = _load_png(WEAPON_T2)
	if body == null or w0 == null or w2 == null:
		push_error("missing art for contact sheet")
		quit(1)
		return
	var sheet := Image.create(CELL * 2 + PAD * 3, CELL + PAD * 2, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.08, 0.12, 0.1, 1.0))
	_blit_frame(sheet, body, w0, PAD, PAD)
	_blit_frame(sheet, body, w2, PAD * 2 + CELL, PAD)
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


func _blit_frame(sheet: Image, body: Image, weapon: Image, ox: int, oy: int) -> void:
	for y: int in CELL:
		for x: int in CELL:
			if x < body.get_width() and y < body.get_height():
				sheet.set_pixel(ox + x, oy + y, body.get_pixel(x, y))
	var wx: int = ox + HAND_X - int(GRIP.x)
	var wy: int = oy + HAND_Y - int(GRIP.y)
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
