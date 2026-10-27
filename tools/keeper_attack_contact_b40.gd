extends SceneTree
## Contact sheet: Keeper attack 1–8 × craftable weapon rows (battle_view layout).
## godot --headless --path . --script res://tools/keeper_attack_contact_b40.gd

const CombatAnimsConfigScript := preload("res://scripts/battle/combat_anims_config.gd")

const OUT_PATH: String = "/cursor/stores/self/caps/keeper_attack_contact_b40.png"
const ACTOR: String = "keeper"
const CLIP: String = "attack"
const LOGICAL_TOTAL: int = 8
const LABEL_COL_W: int = 112
const ROW_LABEL_H: int = 18
const GAP: int = 8


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	CombatAnimsConfigScript.reload()
	var rows: Array[Dictionary] = CombatAnimsConfigScript.craft_weapon_rows_for_contact()
	var cell: Vector2i = CombatAnimsConfigScript.contact_cell_size()
	var margin: int = CombatAnimsConfigScript.CONTACT_CELL_MARGIN
	var cols: int = LOGICAL_TOTAL
	var sheet_w: int = LABEL_COL_W + GAP + cols * cell.x + GAP * (cols + 1)
	var sheet_h: int = ROW_LABEL_H + rows.size() * (cell.y + GAP) + GAP
	var sheet := Image.create(sheet_w, sheet_h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.08, 0.12, 0.1, 1.0))
	for row_i: int in rows.size():
		var row: Dictionary = rows[row_i]
		var sprite_id: String = str(row.get("sprite_id", ""))
		var row_y: int = GAP + ROW_LABEL_H + row_i * (cell.y + GAP)
		_draw_row_label(sheet, str(row.get("label", "")), 4, row_y + 8)
		for logical_0: int in LOGICAL_TOTAL:
			var cell_x: int = LABEL_COL_W + GAP + logical_0 * (cell.x + GAP)
			_paint_cell(sheet, sprite_id, logical_0, cell_x, row_y, cell, margin)
	DirAccess.make_dir_recursive_absolute("/cursor/stores/self/caps")
	if sheet.save_png(OUT_PATH) != OK:
		push_error("failed to write %s" % OUT_PATH)
		quit(1)
		return
	print("CONTACT_B40_OK: %s" % OUT_PATH)
	quit(0)


func _paint_cell(
	sheet: Image,
	sprite_id: String,
	logical_0: int,
	cell_x: int,
	cell_y: int,
	cell: Vector2i,
	margin: int,
) -> void:
	var art_frame: int = CombatAnimsConfigScript.art_frame_index(
		ACTOR, CLIP, logical_0, LOGICAL_TOTAL,
	)
	var body_path: String = CombatAnimsConfigScript.modular_body_path(ACTOR, CLIP, art_frame)
	var anchor: Dictionary = CombatAnimsConfigScript.hand_anchor(ACTOR, CLIP, art_frame)
	var rot_index: int = int(anchor.get("rot_index", 0))
	var z: String = str(anchor.get("z", "front"))
	var hx: int = int(anchor.get("hand_x", 0))
	var hy: int = int(anchor.get("hand_y", 0))
	var body: Image = _texture_image(body_path)
	var weapon_path: String = CombatAnimsConfigScript.weapon_texture_for_rot(sprite_id, rot_index)
	var weapon: Image = _texture_image(weapon_path)
	if body == null or weapon == null:
		push_error("missing art for %s frame %d" % [sprite_id, logical_0])
		quit(1)
		return
	var body_origin: Vector2i = Vector2i(cell_x + margin, cell_y + margin)
	var w_top: Vector2 = CombatAnimsConfigScript.weapon_top_left_in_body_texture(hx, hy, sprite_id, rot_index)
	var weapon_origin: Vector2i = Vector2i(cell_x + margin + int(w_top.x), cell_y + margin + int(w_top.y))
	if z == "behind":
		_blit_image(sheet, weapon, weapon_origin)
		_blit_image(sheet, body, body_origin)
	else:
		_blit_image(sheet, body, body_origin)
		_blit_image(sheet, weapon, weapon_origin)


func _texture_image(path: String) -> Image:
	var tex: Texture2D = load(path) as Texture2D
	if tex == null:
		return null
	var img: Image = tex.get_image()
	if img != null and img.is_compressed():
		img.decompress()
	return img


func _blit_image(sheet: Image, src: Image, origin: Vector2i) -> void:
	for y: int in src.get_height():
		for x: int in src.get_width():
			var c: Color = src.get_pixel(x, y)
			if c.a < 0.01:
				continue
			var px: int = origin.x + x
			var py: int = origin.y + y
			if px < 0 or py < 0 or px >= sheet.get_width() or py >= sheet.get_height():
				continue
			var under: Color = sheet.get_pixel(px, py)
			sheet.set_pixel(px, py, under.lerp(c, c.a))


func _draw_row_label(sheet: Image, text: String, x: int, y: int) -> void:
	var ink: Color = Color(0.85, 0.92, 0.88, 1.0)
	for i: int in text.length():
		_draw_char(sheet, text[i], x + i * 7, y, ink)


func _draw_char(sheet: Image, ch: String, x: int, y: int, ink: Color) -> void:
	var glyph: PackedInt32Array = _glyph_rows(ch)
	if glyph.is_empty():
		return
	for row: int in 7:
		var bits: int = glyph[row]
		for col: int in 5:
			if (bits >> (4 - col)) & 1:
				var px: int = x + col
				var py: int = y + row
				if px >= 0 and py >= 0 and px < sheet.get_width() and py < sheet.get_height():
					sheet.set_pixel(px, py, ink)


func _glyph_rows(ch: String) -> PackedInt32Array:
	match ch:
		"A":
			return PackedInt32Array([0b01110, 0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001])
		"B":
			return PackedInt32Array([0b11110, 0b10001, 0b11110, 0b10001, 0b10001, 0b10001, 0b11110])
		"E":
			return PackedInt32Array([0b11111, 0b10000, 0b11110, 0b10000, 0b10000, 0b10000, 0b11111])
		"F":
			return PackedInt32Array([0b11111, 0b10000, 0b11110, 0b10000, 0b10000, 0b10000, 0b10000])
		"H":
			return PackedInt32Array([0b10001, 0b10001, 0b11111, 0b10001, 0b10001, 0b10001, 0b10001])
		"I":
			return PackedInt32Array([0b01110, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110])
		"L":
			return PackedInt32Array([0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b10000, 0b11111])
		"N":
			return PackedInt32Array([0b10001, 0b11001, 0b10101, 0b10011, 0b10001, 0b10001, 0b10001])
		"O":
			return PackedInt32Array([0b01110, 0b10001, 0b10001, 0b10001, 0b10001, 0b10001, 0b01110])
		"R":
			return PackedInt32Array([0b11110, 0b10001, 0b10001, 0b11110, 0b10100, 0b10010, 0b10001])
		"S":
			return PackedInt32Array([0b01111, 0b10000, 0b10000, 0b01110, 0b00001, 0b00001, 0b11110])
		"T":
			return PackedInt32Array([0b11111, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100])
		"W":
			return PackedInt32Array([0b10001, 0b10001, 0b10001, 0b10101, 0b10101, 0b11011, 0b10001])
		"a":
			return PackedInt32Array([0b00000, 0b00000, 0b01110, 0b00001, 0b01111, 0b10001, 0b01111])
		"b":
			return PackedInt32Array([0b10000, 0b10000, 0b10110, 0b11001, 0b10001, 0b10001, 0b11110])
		"d":
			return PackedInt32Array([0b00001, 0b00001, 0b01101, 0b10011, 0b10001, 0b10001, 0b01111])
		"e":
			return PackedInt32Array([0b00000, 0b00000, 0b01110, 0b10001, 0b11111, 0b10000, 0b01111])
		"f":
			return PackedInt32Array([0b00110, 0b01001, 0b01000, 0b11100, 0b01000, 0b01000, 0b01000])
		"h":
			return PackedInt32Array([0b10000, 0b10000, 0b10110, 0b11001, 0b10001, 0b10001, 0b10001])
		"i":
			return PackedInt32Array([0b00100, 0b00000, 0b01100, 0b00100, 0b00100, 0b00100, 0b01110])
		"l":
			return PackedInt32Array([0b01100, 0b00100, 0b00100, 0b00100, 0b00100, 0b00100, 0b01110])
		"m":
			return PackedInt32Array([0b00000, 0b00000, 0b11010, 0b10101, 0b10101, 0b10001, 0b10001])
		"n":
			return PackedInt32Array([0b00000, 0b00000, 0b10110, 0b11001, 0b10001, 0b10001, 0b10001])
		"o":
			return PackedInt32Array([0b00000, 0b00000, 0b01110, 0b10001, 0b10001, 0b10001, 0b01110])
		"r":
			return PackedInt32Array([0b00000, 0b00000, 0b10110, 0b11001, 0b10000, 0b10000, 0b10000])
		"s":
			return PackedInt32Array([0b00000, 0b00000, 0b01111, 0b10000, 0b01110, 0b00001, 0b11110])
		"t":
			return PackedInt32Array([0b01000, 0b01000, 0b11110, 0b01000, 0b01000, 0b01001, 0b00110])
		"w":
			return PackedInt32Array([0b00000, 0b00000, 0b10001, 0b10001, 0b10101, 0b10101, 0b01010])
		_:
			return PackedInt32Array()
