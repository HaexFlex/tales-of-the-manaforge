class_name EchoTheme
extends RefCounted
## Ink-water Echo chrome. Panels are opaque art at 0.88; sizes stay on the 40+8n tile.

const ART: String = "res://assets/ui/echo/"
const PANEL: String = ART + "ink_panel_9s_48.png"
const PANEL_PLAIN: String = ART + "ink_panel_plain_9s_48.png"
const SPEECH_TEX: String = ART + "speech_box_432x132.png"
const PLATE: String = ART + "echo_chamber_bg_inkwater_1280x720.png"
const JERSEY: String = "res://assets/fonts/font_echo_title_jersey.tres"
const BODY_FONT: String = "res://assets/fonts/font_body_silver19.tres"
const PRIMARY_FONT: String = "res://assets/fonts/font_primary_silver38_bold.tres"

const PANEL_ALPHA: float = 0.88
const PANEL_MARGIN: int = 20
const TILE: int = 8
const PANEL_BASE: int = 40

const PEARL: Color = Color8(241, 234, 216)
const INK_OUTLINE: Color = Color8(4, 13, 16)
const MUTED: Color = Color8(143, 184, 176)
const GOLD: Color = Color8(255, 208, 138)
const AMBER: Color = Color8(255, 179, 71)
const CYAN: Color = Color8(143, 227, 230)
const KOI: Color = Color8(255, 138, 107)
const TEAL_GLOW: Color = Color8(47, 168, 154)
const DIM: Color = Color(0, 0, 0, 150.0 / 255.0)

const BODY_SIZE: int = 19
const TITLE_SIZE: int = 37
const SMALL_TITLE_SIZE: int = 19
const PRIMARY_SIZE: int = 38
const LINE_PITCH: int = 20
## Jersey 10 cap ink (top of H to baseline), scaled from the theme_pkg size-30 measure of 16.
const JERSEY_CAP_19: int = 10
const JERSEY_CAP_37: int = 20

const DESIGN_W: float = 960.0
const SPEECH_BOX: Rect2 = Rect2(264, 128, 432, 132)
const SPEECH_TEXT_W: float = 408.0
const SPEECH_LINES: int = 3
const PAGE_CHARS_MAX: int = 215
const BOTTOM_BAR: Rect2 = Rect2(28, 372, 904, 144)
const CHAMBER_PANEL: Rect2 = Rect2(216, 400, 528, 104)
const LEAVE_BTN: Rect2 = Rect2(236, 440, 168, 44)
const FACE_BTN: Rect2 = Rect2(444, 436, 280, 52)
const CLOSE_BTN: Rect2 = Rect2(892, 26, 44, 44)
## Top-left status chip. Kept clear of the centred title plate.
const ATTEMPT_CHIP: Rect2 = Rect2(12, 12, 132, 44)
const KEEPER_CX: float = 200.0
const ECHO_CX: float = 760.0
const FEET_Y: float = 340.0
const SPRITE: float = 256.0
const SPRITE_Y: float = 94.0
const CROP_16: Rect2 = Rect2(160, 90, 960, 540)
const CROP_20: Rect2 = Rect2(40, 90, 1200, 540)

const SALVE_MAX: int = 2
const MENU_SLOTS: PackedStringArray = ["strike", "ability", "items", "brace", "flee", "spare"]


static func shift_for_width(width: float) -> float:
	return maxf(0.0, (width - DESIGN_W) * 0.5)


static func shift() -> float:
	return Ui540.center_shift_x()


static func at(design: Rect2) -> Rect2:
	return Rect2(design.position + Vector2(shift(), 0), design.size)


static func tiles(px: float) -> bool:
	if px + 0.01 < float(PANEL_BASE):
		return false
	return is_equal_approx(fmod(px - float(PANEL_BASE), float(TILE)), 0.0)


static func snap_panel(px: float) -> float:
	if px <= float(PANEL_BASE):
		return float(PANEL_BASE)
	var steps: float = (px - float(PANEL_BASE)) / float(TILE)
	return float(PANEL_BASE) + float(TILE) * round(steps)


static func panel_ok(size: Vector2) -> bool:
	return tiles(size.x) and tiles(size.y)


static func jersey_centre_delta(size: int) -> int:
	## theme_pkg rule: spacing_top - spacing_bottom = descent - ascent + cap.
	var font: Font = load("res://assets/fonts/Jersey10-Regular.ttf")
	if font == null:
		return 999
	var cap: int = JERSEY_CAP_37 if size >= TITLE_SIZE else JERSEY_CAP_19
	return int(round(font.get_descent(size) - font.get_ascent(size) + float(cap)))


static func jersey_font(size: int) -> FontVariation:
	var v := FontVariation.new()
	v.base_font = load(JERSEY)
	var delta: int = jersey_centre_delta(size)
	if delta > 0:
		v.spacing_bottom = -delta
	elif delta < 0:
		v.spacing_top = delta
	return v


static func jersey_legible(size: int) -> bool:
	var font: Font = jersey_font(size)
	var box: Vector2 = font.get_string_size("H", HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	if box.x < 4.0 or box.y < 8.0:
		return false
	if box.y > float(size) + 8.0:
		return false
	return jersey_centre_delta(size) == 0


static func style_body(lbl: Label, muted: bool = false) -> void:
	lbl.add_theme_font_override("font", load(BODY_FONT))
	lbl.add_theme_font_size_override("font_size", BODY_SIZE)
	lbl.add_theme_color_override("font_color", MUTED if muted else PEARL)
	lbl.add_theme_color_override("font_outline_color", INK_OUTLINE)
	lbl.add_theme_constant_override("outline_size", 1)


static func style_title(lbl: Label, big: bool) -> void:
	var size: int = TITLE_SIZE if big else SMALL_TITLE_SIZE
	lbl.add_theme_font_override("font", jersey_font(size))
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", PEARL)
	lbl.add_theme_color_override("font_outline_color", INK_OUTLINE)
	lbl.add_theme_constant_override("outline_size", 1)
	lbl.add_theme_color_override("font_shadow_color", TEAL_GLOW)
	lbl.add_theme_constant_override("shadow_offset_x", 0)
	lbl.add_theme_constant_override("shadow_offset_y", 0)
	lbl.add_theme_constant_override("shadow_outline_size", 2)


static func panel_style(plain: bool) -> StyleBoxTexture:
	var box := StyleBoxTexture.new()
	box.texture = load(PANEL_PLAIN if plain else PANEL)
	box.texture_margin_left = PANEL_MARGIN
	box.texture_margin_top = PANEL_MARGIN
	box.texture_margin_right = PANEL_MARGIN
	box.texture_margin_bottom = PANEL_MARGIN
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	return box


static func paint_panel(panel: Panel, plain: bool) -> void:
	panel.add_theme_stylebox_override("panel", panel_style(plain))
	panel.self_modulate = Color(1, 1, 1, PANEL_ALPHA)
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


static func button_style(state: String) -> StyleBoxTexture:
	var file: String = ART + "ink_button_9s_%s_24x24.png" % state
	if state == "focus":
		file = ART + "ink_button_9s_focus_30x30.png"
	var box := StyleBoxTexture.new()
	box.texture = load(file)
	var margin: int = 9 if state == "focus" else 6
	box.texture_margin_left = margin
	box.texture_margin_top = margin
	box.texture_margin_right = margin
	box.texture_margin_bottom = margin
	if state == "pressed":
		box.content_margin_left = 8
		box.content_margin_top = 5
		box.content_margin_right = 8
		box.content_margin_bottom = 5
	elif state != "focus":
		box.content_margin_left = 8
		box.content_margin_top = 4
		box.content_margin_right = 8
		box.content_margin_bottom = 6
	if state == "focus":
		box.expand_margin_left = 3
		box.expand_margin_top = 3
		box.expand_margin_right = 3
		box.expand_margin_bottom = 3
	return box


static func paint_button(btn: Button, primary: bool) -> void:
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		btn.add_theme_stylebox_override(state, button_style(state))
	btn.add_theme_stylebox_override("hover_pressed", button_style("pressed"))
	var font: Font = load(PRIMARY_FONT if primary else BODY_FONT)
	var size: int = PRIMARY_SIZE if primary else BODY_SIZE
	btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", size)
	for color_name: StringName in [
		&"font_color", &"font_hover_color", &"font_pressed_color",
		&"font_hover_pressed_color", &"font_focus_color",
	]:
		btn.add_theme_color_override(color_name, PEARL)
	btn.add_theme_color_override(&"font_disabled_color", MUTED)
	btn.add_theme_color_override(&"font_outline_color", INK_OUTLINE)
	btn.add_theme_constant_override(&"outline_size", 1)
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


static func line_count(text: String, font: Font) -> int:
	var words: PackedStringArray = text.split(" ", false)
	if words.is_empty():
		return 0
	var lines: int = 1
	var line: String = ""
	for word: String in words:
		var trial: String = word if line == "" else line + " " + word
		var width: float = font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, BODY_SIZE).x
		if width <= SPEECH_TEXT_W or line == "":
			line = trial
		else:
			lines += 1
			line = word
	return lines


static func paginate(text: String) -> PackedStringArray:
	## Three Silver-19 lines, about 200 characters, breaking on a sentence when one fits.
	var font: Font = load(BODY_FONT)
	var pages: PackedStringArray = PackedStringArray()
	var rest: String = text.strip_edges()
	while rest != "":
		var page: String = _fit_page(rest, font)
		if page == "":
			page = rest
			rest = ""
		else:
			rest = rest.substr(page.length()).strip_edges()
		pages.append(page)
	return pages


static func _fit_page(text: String, font: Font) -> String:
	var best: String = ""
	var sentence: String = ""
	var i: int = 0
	while i < text.length():
		var ch: String = text.substr(i, 1)
		var end: int = i + 1
		if ch != " ":
			var space: int = text.find(" ", i)
			end = text.length() if space < 0 else space
		var trial: String = text.substr(0, end).strip_edges()
		if trial == "":
			i = end
			continue
		if line_count(trial, font) > SPEECH_LINES or trial.length() > PAGE_CHARS_MAX:
			break
		best = trial
		if _sentence_end(trial):
			sentence = trial
		i = end
	if i >= text.length():
		return best
	if sentence != "" and sentence.length() >= 40:
		return sentence
	return best


static func _sentence_end(text: String) -> bool:
	if text.is_empty():
		return false
	var last: String = text.substr(text.length() - 1, 1)
	return last == "." or last == "!" or last == "?"
