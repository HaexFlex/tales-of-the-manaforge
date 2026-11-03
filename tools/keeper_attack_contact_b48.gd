extends SceneTree
## Contact sheet: sword / wand / bow attack clips × craft weapon rows (Brief 48).
## godot --headless --path . --script res://tools/keeper_attack_contact_b48.gd

const CombatAnimsConfigScript := preload("res://scripts/battle/combat_anims_config.gd")

const OUT_PATH: String = "/cursor/stores/self/caps/keeper_attack_contact_b48.png"
const GIF_PATH: String = "/cursor/stores/self/caps/keeper_attack_b48.gif"
const ACTOR: String = "keeper"
const NEAREST_SCALE: int = 4
const LABEL_COL_W: int = 112 * NEAREST_SCALE
const ROW_LABEL_H: int = 18 * NEAREST_SCALE
const GAP: int = 8 * NEAREST_SCALE
const STRING_COLOR: Color = Color(0.55, 0.42, 0.28, 1.0)


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	CombatAnimsConfigScript.reload()
	var rows: Array[Dictionary] = CombatAnimsConfigScript.craft_weapon_rows_for_contact()
	var cell: Vector2i = CombatAnimsConfigScript.contact_cell_size_scaled(NEAREST_SCALE)
	var margin: int = CombatAnimsConfigScript.CONTACT_CELL_MARGIN * NEAREST_SCALE
	var sheet_w: int = LABEL_COL_W + GAP
	for row: Dictionary in rows:
		var clip: String = str(row.get("clip", "attack"))
		var timing: Dictionary = CombatAnimsConfigScript.timing("party", clip)
		var cols: int = int(timing.get("frames", 8))
		sheet_w = maxi(sheet_w, LABEL_COL_W + GAP + cols * (cell.x + GAP) + GAP)
	var sheet_h: int = ROW_LABEL_H + rows.size() * (cell.y + GAP) + GAP
	var sheet := Image.create(sheet_w, sheet_h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.08, 0.12, 0.1, 1.0))
	for row_i: int in rows.size():
		var row: Dictionary = rows[row_i]
		var sprite_id: String = str(row.get("sprite_id", ""))
		var clip: String = str(row.get("clip", "attack"))
		var timing: Dictionary = CombatAnimsConfigScript.timing("party", clip)
		var cols: int = int(timing.get("frames", 8))
		var row_y: int = GAP + ROW_LABEL_H + row_i * (cell.y + GAP)
		_draw_row_label(sheet, str(row.get("label", "")), 4 * NEAREST_SCALE, row_y + 8 * NEAREST_SCALE)
		for logical_0: int in cols:
			var cell_x: int = LABEL_COL_W + GAP + logical_0 * (cell.x + GAP)
			_paint_cell(sheet, sprite_id, clip, logical_0, cols, cell_x, row_y, cell, margin)
	DirAccess.make_dir_recursive_absolute("/cursor/stores/self/caps")
	if sheet.save_png(OUT_PATH) != OK:
		push_error("failed to write %s" % OUT_PATH)
		quit(1)
		return
	print(
		"CONTACT_B48_OK: %s (%dx%d, cell %dx%d @ %dx)"
		% [OUT_PATH, sheet_w, sheet_h, cell.x, cell.y, NEAREST_SCALE],
	)
	quit(0)


func _paint_cell(
	sheet: Image,
	sprite_id: String,
	clip: String,
	logical_0: int,
	logical_total: int,
	cell_x: int,
	cell_y: int,
	cell: Vector2i,
	margin: int,
) -> void:
	var art_frame: int = CombatAnimsConfigScript.art_frame_index(
		ACTOR, clip, logical_0, logical_total,
	)
	var body_path: String = CombatAnimsConfigScript.modular_body_path(ACTOR, clip, art_frame)
	var anchor: Dictionary = CombatAnimsConfigScript.hand_anchor(ACTOR, clip, art_frame)
	var rot_index: int = int(anchor.get("rot_index", 0))
	var z: String = str(anchor.get("z", "front"))
	var hx: int = int(anchor.get("hand_x", 0))
	var hy: int = int(anchor.get("hand_y", 0))
	var body: Image = _texture_image(body_path)
	var weapon_path: String = CombatAnimsConfigScript.weapon_texture_for_rot(sprite_id, rot_index)
	var weapon: Image = _texture_image(weapon_path)
	if body == null or weapon == null:
		push_error("missing art for %s %s frame %d" % [sprite_id, clip, logical_0])
		quit(1)
		return
	var body_origin: Vector2i = Vector2i(cell_x + margin, cell_y + margin)
	var w_top: Vector2 = CombatAnimsConfigScript.weapon_top_left_in_body_texture(hx, hy, sprite_id, rot_index)
	var weapon_origin: Vector2i = Vector2i(
		body_origin.x + int(w_top.x) * NEAREST_SCALE,
		body_origin.y + int(w_top.y) * NEAREST_SCALE,
	)
	if z == "behind":
		_blit_nearest(sheet, weapon, weapon_origin)
		_blit_nearest(sheet, body, body_origin)
	else:
		_blit_nearest(sheet, body, body_origin)
		_blit_nearest(sheet, weapon, weapon_origin)
	if clip == "attack_bow":
		var hand2_x: int = int(anchor.get("hand2_x", hx))
		var hand2_y: int = int(anchor.get("hand2_y", hy))
		var string_draw: float = float(anchor.get("string_draw", 0.0))
		var pts: PackedVector2Array = CombatAnimsConfigScript.bow_string_points_in_body(
			hx, hy, hand2_x, hand2_y, sprite_id, rot_index, string_draw,
		)
		for i: int in range(pts.size() - 1):
			_draw_line(
				sheet,
				body_origin
				+ Vector2i(int(pts[i].x) * NEAREST_SCALE, int(pts[i].y) * NEAREST_SCALE),
				body_origin
				+ Vector2i(
					int(pts[i + 1].x) * NEAREST_SCALE, int(pts[i + 1].y) * NEAREST_SCALE
				),
				STRING_COLOR,
			)
		if CombatAnimsConfigScript.bow_arrow_nocked_visible(clip, art_frame):
			var angle: float = CombatAnimsConfigScript.arrow_angle_rad(hx, hy, hand2_x, hand2_y)
			var arrow: Image = _texture_image(CombatAnimsConfigScript.ARROW_SPRITE_PATH)
			if arrow != null:
				var arrow_tl: Vector2 = CombatAnimsConfigScript.arrow_top_left_in_body(
					hand2_x, hand2_y, angle,
				)
				_blit_arrow_rotated(
					sheet,
					arrow,
					body_origin
					+ Vector2i(int(arrow_tl.x) * NEAREST_SCALE, int(arrow_tl.y) * NEAREST_SCALE),
					angle,
					NEAREST_SCALE,
				)
	if clip == "attack_wand" and CombatAnimsConfigScript.wand_spark_visible(clip, art_frame):
		var spark_strip: Image = _texture_image(CombatAnimsConfigScript.WAND_SPARK_PATH)
		if spark_strip != null:
			var spark_frame: int = (art_frame - 2) % 4
			var tip: Vector2 = CombatAnimsConfigScript.wand_tip_in_body_texture(anchor)
			var spark_origin: Vector2i = body_origin + Vector2i(
				(int(tip.x) - 4) * NEAREST_SCALE, (int(tip.y) - 4) * NEAREST_SCALE,
			)
			var spark_cell := Image.create(8, 8, false, Image.FORMAT_RGBA8)
			for y: int in 8:
				for x: int in 8:
					spark_cell.set_pixel(x, y, spark_strip.get_pixel(spark_frame * 8 + x, y))
			_blit_nearest(sheet, spark_cell, spark_origin)


func _blit_arrow_rotated(
	sheet: Image, arrow: Image, origin: Vector2i, angle_rad: float, scale: int,
) -> void:
	var c: float = cos(angle_rad)
	var s: float = sin(angle_rad)
	for y: int in arrow.get_height():
		for x: int in arrow.get_width():
			var col: Color = arrow.get_pixel(x, y)
			if col.a < 0.01:
				continue
			var lx: float = float(x)
			var ly: float = float(y)
			var bx: int = int(roundf(lx * c - ly * s))
			var by: int = int(roundf(lx * s + ly * c))
			for dy: int in scale:
				for dx: int in scale:
					var rx: int = origin.x + bx * scale + dx
					var ry: int = origin.y + by * scale + dy
					if rx < 0 or ry < 0 or rx >= sheet.get_width() or ry >= sheet.get_height():
						continue
					var under: Color = sheet.get_pixel(rx, ry)
					sheet.set_pixel(rx, ry, under.lerp(col, col.a))


func _blit_nearest(sheet: Image, src: Image, origin: Vector2i) -> void:
	for y: int in src.get_height():
		for x: int in src.get_width():
			var col: Color = src.get_pixel(x, y)
			if col.a < 0.01:
				continue
			for dy: int in NEAREST_SCALE:
				for dx: int in NEAREST_SCALE:
					var px: int = origin.x + x * NEAREST_SCALE + dx
					var py: int = origin.y + y * NEAREST_SCALE + dy
					if px < 0 or py < 0 or px >= sheet.get_width() or py >= sheet.get_height():
						continue
					var under: Color = sheet.get_pixel(px, py)
					sheet.set_pixel(px, py, under.lerp(col, col.a))


func _draw_line(sheet: Image, from: Vector2i, to: Vector2i, color: Color) -> void:
	for thick: int in NEAREST_SCALE:
		_draw_line_1px(sheet, from + Vector2i(thick, 0), to + Vector2i(thick, 0), color)


func _draw_line_1px(sheet: Image, from: Vector2i, to: Vector2i, color: Color) -> void:
	var dx: int = absi(to.x - from.x)
	var dy: int = -absi(to.y - from.y)
	var sx: int = 1 if from.x < to.x else -1
	var sy: int = 1 if from.y < to.y else -1
	var err: int = dx + dy
	var x: int = from.x
	var y: int = from.y
	while true:
		if x >= 0 and y >= 0 and x < sheet.get_width() and y < sheet.get_height():
			sheet.set_pixel(x, y, color)
		if x == to.x and y == to.y:
			break
		var e2: int = 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy


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
		_draw_char(sheet, text[i], x + i * 7 * NEAREST_SCALE, y, ink, NEAREST_SCALE)


func _draw_char(sheet: Image, ch: String, x: int, y: int, ink: Color, scale: int) -> void:
	var glyph: PackedInt32Array = _glyph_rows(ch)
	if glyph.is_empty():
		return
	for row: int in 7:
		var bits: int = glyph[row]
		for col: int in 5:
			if (bits >> (4 - col)) & 1:
				for dy: int in scale:
					for dx: int in scale:
						var px: int = x + col * scale + dx
						var py: int = y + row * scale + dy
						if px >= 0 and py >= 0 and px < sheet.get_width() and py < sheet.get_height():
							sheet.set_pixel(px, py, ink)


func _glyph_rows(ch: String) -> PackedInt32Array:
	var font: Dictionary = {
		"A": [14, 17, 17, 17, 17, 17, 10],
		"B": [30, 17, 17, 30, 17, 17, 30],
		"C": [14, 17, 16, 16, 16, 17, 14],
		"D": [30, 17, 17, 17, 17, 17, 30],
		"E": [31, 16, 16, 30, 16, 16, 31],
		"F": [31, 16, 16, 30, 16, 16, 16],
		"G": [14, 17, 16, 19, 17, 17, 14],
		"H": [17, 17, 17, 31, 17, 17, 17],
		"I": [14, 4, 4, 4, 4, 4, 14],
		"L": [16, 16, 16, 16, 16, 16, 31],
		"N": [17, 25, 25, 21, 19, 19, 17],
		"O": [14, 17, 17, 17, 17, 17, 14],
		"R": [30, 17, 17, 30, 20, 18, 19],
		"S": [14, 17, 16, 14, 1, 17, 14],
		"T": [31, 4, 4, 4, 4, 4, 4],
		"W": [17, 17, 17, 21, 21, 21, 17],
		"a": [0, 0, 14, 1, 15, 17, 15],
		"b": [16, 16, 30, 17, 17, 17, 30],
		"d": [1, 1, 15, 17, 17, 17, 15],
		"e": [0, 0, 14, 17, 31, 16, 15],
		"f": [6, 17, 16, 30, 16, 16, 16],
		"g": [0, 0, 15, 17, 15, 1, 14],
		"h": [16, 16, 22, 25, 17, 17, 17],
		"i": [4, 0, 12, 4, 4, 4, 14],
		"l": [12, 4, 4, 4, 4, 4, 14],
		"n": [0, 0, 22, 25, 17, 17, 17],
		"o": [0, 0, 14, 17, 17, 17, 14],
		"r": [0, 0, 22, 25, 16, 16, 16],
		"s": [0, 0, 14, 16, 14, 1, 30],
		"t": [4, 4, 30, 4, 4, 5, 2],
		"w": [0, 0, 17, 17, 21, 21, 17],
		" ": [0, 0, 0, 0, 0, 0, 0],
	}
	if not font.has(ch):
		return PackedInt32Array()
	return font[ch] as PackedInt32Array
